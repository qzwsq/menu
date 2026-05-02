import asyncio
import logging

from app.repository.dish_template_repo import get_dish_repo
from app.repository.menu_repo import get_menu_repo
from app.repository.shopping_repo import get_shopping_repo
from app.schema.menu import CreateMenuRequest, CreateMenuResponse, MealItem, MenuBrief, MenuDetail
from app.schema.shopping import (
    GenerateShoppingRequest,
    ShoppingFood,
    ShoppingMeal,
)
from app.service.dish_service import get_dish_service
from app.service.shopping_service import ShoppingService

logger = logging.getLogger(__name__)


class MenuService:
    def __init__(self):
        self._menu_repo = get_menu_repo()
        self._shopping_repo = get_shopping_repo()
        self._dish_repo = get_dish_repo()

    async def create(self, req: CreateMenuRequest) -> CreateMenuResponse:
        # 1. 插入 menus
        menu = await self._menu_repo.create_menu(
            name=req.name,
            diner_count=req.diner_count,
            start_date=req.start_date,
            end_date=req.end_date,
        )

        # 2. 插入 menu_meals
        days_data = [
            {"day_date": d.day_date, "meals": d.meals}
            for d in req.days
        ]
        await self._menu_repo.create_meals(menu.id, days_data)

        # 3. 生成采购清单
        shopping_list_id: int | None = None
        if req.generate_shopping:
            sl = await self._generate_shopping(
                menu_id=menu.id,
                diner_count=req.diner_count,
                week_start=req.start_date,
                days=req.days,
            )
            shopping_list_id = sl.id
            await self._menu_repo.update_menu(
                menu.id,
                shopping_list_id=shopping_list_id,
                has_shopping_list=True,
            )

        return CreateMenuResponse(
            id=menu.id,
            name=menu.name,
            diner_count=menu.diner_count,
            days_count=len(req.days),
            shopping_list_id=shopping_list_id,
        )

    async def _generate_shopping(
        self,
        menu_id: int,
        diner_count: int,
        week_start: str,
        days: list,
    ):
        shopping_meals = []
        for day_idx, day in enumerate(days):
            foods = self._extract_foods(day.meals)
            logger.info(
                "[menu_id=%s day=%s] extracted_foods=%s",
                menu_id, day_idx + 1,
                [(fn, fid) for fn, fid in foods],
            )
            results = await asyncio.gather(*[
                self._lookup_ingredients(fn, fid) for fn, fid in foods
            ])
            for (fn, _fid), ingredients in zip(foods, results):
                logger.info(
                    "[menu_id=%s day=%s] food=%s ingredients_count=%s",
                    menu_id, day_idx + 1, fn, len(ingredients),
                )
            shopping_foods = [
                ShoppingFood(food_name=fn, servings=1, ingredients=ingredients)
                for (fn, _fid), ingredients in zip(foods, results)
            ]
            shopping_meals.append(
                ShoppingMeal(day_of_week=day_idx + 1, foods=shopping_foods)
            )

        total_foods = sum(len(m.foods) for m in shopping_meals)
        total_ingredients = sum(len(f.ingredients) for m in shopping_meals for f in m.foods)
        logger.info(
            "[menu_id=%s] total_foods=%s total_ingredients=%s -> calling ShoppingService.generate",
            menu_id, total_foods, total_ingredients,
        )

        svc = ShoppingService()
        result = await svc.generate(
            GenerateShoppingRequest(
                week_start=week_start,
                diner_count=diner_count,
                meals=shopping_meals,
            )
        )

        logger.info(
            "[menu_id=%s] shopping_result categories=%s item_count=%s",
            menu_id,
            [c.name for c in result.categories],
            sum(len(c.items) for c in result.categories),
        )

        categories_data = [c.model_dump() for c in result.categories]
        sl = await self._shopping_repo.create(
            menu_id=menu_id,
            diner_count=diner_count,
            week_start=week_start,
            categories=categories_data,
        )
        return sl

    def _extract_foods(self, meals: dict) -> list[tuple[str, int | None]]:
        """从 meals JSON 中提取所有食物 (name, id)（去重）"""
        seen: set[str] = set()
        result: list[tuple[str, int | None]] = []

        def add(item):
            if isinstance(item, dict):
                name = item.get("name", "")
                fid = item.get("id")
            else:
                name = str(item)
                fid = None
            if name and name not in seen:
                seen.add(name)
                result.append((name, fid))

        for item in meals.get("fruit", []) or []:
            add(item)

        for meal_key in ("breakfast", "lunch", "dinner"):
            meal = meals.get(meal_key, {}) or {}
            for cat in ("staple", "dish", "drink"):
                for item in meal.get(cat, []) or []:
                    add(item)

        return result

    async def _lookup_ingredients(self, food_name: str, food_id = None):
        """从 dish_templates 查找食材配置，优先用 id；未找到时调用 LLM 生成并回写数据库"""
        from app.schema.dish import IngredientItem

        # 过滤无效 id：None、0、空字符串
        effective_id = food_id if food_id and food_id != 0 else None

        if effective_id is not None:
            template = await self._dish_repo.get_by_id(str(effective_id))
        else:
            template = await self._dish_repo.get_by_name(food_name)

        if template and template.ingredients:
            logger.info(
                "[lookup] food=%s template_id=%s ingredients=%s from_db",
                food_name, template.id, len(template.ingredients),
            )
            return [IngredientItem(**i) for i in template.ingredients]

        if template:
            logger.info("[lookup] food=%s template_id=%s no_ingredients -> calling LLM", food_name, template.id)
            dish_svc = get_dish_service()
            result = await dish_svc.generate_ingredients(food_name)
            logger.info(
                "[lookup] food=%s LLM_result ingredients=%s",
                food_name, len(result),
            )
            template.ingredients = result
            template.created_by_llm = True
            template.llm_model = dish_svc.llm.config.model
            await self._dish_repo.save(template)
            return [IngredientItem(**i) for i in result]

        logger.info("[lookup] food=%s template_not_found", food_name)
        return []

    async def list_menus(self, page: int = 1, page_size: int = 20) -> tuple[list[MenuBrief], int]:
        menus, total = await self._menu_repo.list_menus(page=page, page_size=page_size)
        items = [
            MenuBrief(
                id=m.id,
                name=m.name,
                diner_count=m.diner_count,
                start_date=m.start_date,
                end_date=m.end_date,
                has_shopping_list=m.has_shopping_list,
                shopping_list_id=m.shopping_list_id,
                created_at=m.created_at.isoformat() if m.created_at else None,
            )
            for m in menus
        ]
        return items, total

    async def get_menu(self, menu_id: int) -> MenuDetail | None:
        menu = await self._menu_repo.get_menu(menu_id)
        if menu is None:
            return None
        meals = await self._menu_repo.get_meals(menu_id)
        return MenuDetail(
            id=menu.id,
            name=menu.name,
            diner_count=menu.diner_count,
            start_date=menu.start_date,
            end_date=menu.end_date,
            has_shopping_list=menu.has_shopping_list,
            shopping_list_id=menu.shopping_list_id,
            meals=[
                MealItem(id=m.id, day_date=m.day_date, meals_data=m.meals_data)
                for m in meals
            ],
        )

    async def delete_menu(self, menu_id: int, delete_shopping: bool = False) -> bool:
        if delete_shopping:
            sl = await self._shopping_repo.get_by_menu(menu_id)
            if sl:
                await self._shopping_repo.delete(sl.id)
        return await self._menu_repo.delete_menu(menu_id)


_instance: MenuService | None = None


def get_menu_service() -> MenuService:
    if _instance is None:
        raise RuntimeError("MenuService not initialized")
    return _instance


def init_menu_service() -> None:
    global _instance
    _instance = MenuService()
