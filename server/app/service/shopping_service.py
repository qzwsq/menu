import json
import logging
from collections import defaultdict

from tenacity import retry, stop_after_attempt

from app.external.llm_client import get_llm
from app.schema.dish import IngredientItem
from app.schema.shopping import (
    GenerateShoppingRequest,
    GenerateShoppingResponse,
    ShoppingCategory,
    ShoppingItem,
)
from app.util.prompt import render_prompt

logger = logging.getLogger(__name__)


class ShoppingService:
    async def generate(self, req: GenerateShoppingRequest) -> GenerateShoppingResponse:
        # 1. 按菜品聚合食材（保留每个菜品的独立食材清单）
        dish_map: dict[str, list[dict]] = defaultdict(list)
        for meal in req.meals:
            for food in meal.foods:
                factor = food.servings * req.diner_count
                for ing in food.ingredients:
                    dish_map[food.food_name].append({
                        "name": ing.name,
                        "quantity": round(ing.quantity * factor, 1),
                        "unit": ing.unit,
                    })

        logger.info(
            "[shopping] dishes=%s total_ingredients=%s",
            list(dish_map.keys()),
            sum(len(v) for v in dish_map.values()),
        )

        # 2. LLM 分类 + 合并检测
        result = await self._classify(dish_map)

        category_order = result.get("category_order", [])
        ingredient_category = result.get("ingredient_category", {})
        purchase_quantities = result.get("purchase_quantities", {})
        exclude_names = set(result.get("exclude", []))
        merged_dish_names = set(
            md.get("dish", "") for md in result.get("merge_dishes", [])
        )

        # 3. 仅聚合非合并菜品 + 未排除的食材
        ingredient_map: dict[str, dict] = {}
        for dish_name, ingredients in dish_map.items():
            if dish_name in merged_dish_names:
                continue
            for ing in ingredients:
                name = ing["name"]
                if name in exclude_names:
                    continue
                if name not in ingredient_map:
                    ingredient_map[name] = {
                        "total_quantity": 0,
                        "unit": ing["unit"],
                        "source_foods": [],
                    }
                ingredient_map[name]["total_quantity"] += ing["quantity"]
                if dish_name not in ingredient_map[name]["source_foods"]:
                    ingredient_map[name]["source_foods"].append(dish_name)

        # 4. 将合并菜品作为单项加入
        for md in result.get("merge_dishes", []):
            dish_name = md.get("dish", "")
            purchase = md.get("purchase", {})
            cat = md.get("category", "主食")
            if dish_name:
                ingredient_map[dish_name] = {
                    "total_quantity": purchase.get("quantity", 1),
                    "unit": purchase.get("unit", "个"),
                    "source_foods": [dish_name],
                }
                if dish_name not in ingredient_category:
                    ingredient_category[dish_name] = cat
                if dish_name not in purchase_quantities:
                    purchase_quantities[dish_name] = purchase

        logger.info(
            "[shopping] after_merge exclude=%s merged=%s final_ingredients=%s",
            list(exclude_names), list(merged_dish_names), len(ingredient_map),
        )

        # 5. 按分类整理
        categorized: dict[str, list] = defaultdict(list)
        for name, data in ingredient_map.items():
            cat = ingredient_category.get(name, "其他")
            pq = purchase_quantities.get(name, {})
            categorized[cat].append(
                ShoppingItem(
                    name=name,
                    total_quantity=round(data["total_quantity"], 1),
                    unit=data["unit"],
                    purchase_quantity=pq.get("quantity", round(data["total_quantity"], 1)),
                    purchase_unit=pq.get("unit", data["unit"]),
                    source_foods=data["source_foods"],
                )
            )

        categories = []
        for idx, cat_name in enumerate(category_order):
            if cat_name in categorized:
                categories.append(
                    ShoppingCategory(
                        name=cat_name,
                        sort_order=idx + 1,
                        items=categorized[cat_name],
                    )
                )

        if "其他" in categorized and "其他" not in category_order:
            categories.append(
                ShoppingCategory(
                    name="其他",
                    sort_order=len(categories) + 1,
                    items=categorized["其他"],
                )
            )

        return GenerateShoppingResponse(
            week_start=req.week_start,
            diner_count=req.diner_count,
            categories=categories,
        )

    async def _classify(
        self, dish_map: dict[str, list[dict]]
    ) -> dict:
        dishes_json = json.dumps({"dishes": dish_map}, ensure_ascii=False)
        system_prompt, user_prompt = render_prompt(
            "classify_ingredients.md", dishes=dishes_json
        )

        @retry(stop=stop_after_attempt(3), reraise=True)
        async def _call():
            llm = get_llm()
            result = await llm.generate_json(system_prompt, user_prompt)
            logger.info("[shopping] LLM raw result keys=%s", list(result.keys()))
            return result

        try:
            return await _call()
        except Exception as e:
            logger.warning("[shopping] classify failed: %s, fallback to empty", e)
            return {}
