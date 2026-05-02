import uuid

from tenacity import retry, stop_after_attempt

from app.external.llm_client import get_llm
from app.model.dish_template import DishTemplate
from app.repository.dish_template_repo import DishTemplateRepo, get_dish_repo
from app.schema.dish import (
    AddDishRequest,
    DishTemplateResponse,
    IngredientItem,
    NutritionData,
)
from app.util.prompt import render_prompt


class DishService:
    @property
    def repo(self) -> DishTemplateRepo:
        return get_dish_repo()

    @property
    def llm(self):
        return get_llm()

    async def generate_ingredients(
        self, name: str, max_retries: int = 3
    ) -> list[dict]:
        system_prompt, user_prompt = render_prompt(
            "generate_ingredients.md", name=name
        )

        @retry(stop=stop_after_attempt(max_retries), reraise=True)
        async def _call():
            result = await self.llm.generate_json(system_prompt, user_prompt)
            ingredients = result.get("ingredients", [])
            if not isinstance(ingredients, list) or len(ingredients) == 0:
                raise ValueError("ingredients is empty or not a list")
            return [IngredientItem(**i).model_dump() for i in ingredients]

        try:
            return await _call()
        except Exception as e:
            raise RuntimeError(
                f"生成菜品[{name}]食材失败，已重试{max_retries}次: {e}"
            ) from e

    async def add_dish(self, req: AddDishRequest) -> DishTemplateResponse:
        system_prompt, user_prompt = render_prompt("add_dish.md", name=req.name)

        @retry(stop=stop_after_attempt(3), reraise=True)
        async def _call():
            result = await self.llm.generate_json(system_prompt, user_prompt)
            food_type = result.get("food_type", "dish")
            category = result.get("category", "")
            ingredients = result.get("ingredients", [])
            if not food_type or not isinstance(ingredients, list) or len(ingredients) == 0:
                raise ValueError("LLM 返回数据不完整")
            return food_type, category, [IngredientItem(**i).model_dump() for i in ingredients]

        try:
            food_type, category, ingredients = await _call()
        except Exception as e:
            raise RuntimeError(f"生成菜品[{req.name}]失败: {e}") from e

        template = DishTemplate(
            id=str(uuid.uuid4()),
            name=req.name,
            food_type=food_type,
            category=category,
            ingredients=ingredients,
            nutrition={},
            created_by_llm=True,
            llm_model=self.llm.config.model,
        )
        await self.repo.create(template)
        return self._to_response(template)

    async def list_templates(
        self,
        keyword: str | None = None,
        food_type: str | None = None,
        category: str | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[DishTemplateResponse], int]:
        items, total = await self.repo.list_templates(
            keyword=keyword,
            food_type=food_type,
            category=category,
            page=page,
            page_size=page_size,
        )
        result = [self._to_response(item) for item in items]
        return result, total

    async def get_template(self, template_id: str) -> DishTemplateResponse | None:
        template = await self.repo.get_by_id(template_id)
        if template is None:
            return None
        return self._to_response(template)

    async def search(self, q: str, limit: int = 20) -> list[DishTemplateResponse]:
        items = await self.repo.search(q, limit=limit)
        return [self._to_response(item) for item in items]

    def _to_response(self, template: DishTemplate) -> DishTemplateResponse:
        return DishTemplateResponse(
            id=template.id,
            name=template.name,
            food_type=template.food_type,
            category=template.category,
            ingredients=[IngredientItem(**i) for i in template.ingredients],
            nutrition=NutritionData(**template.nutrition),
            created_by_llm=template.created_by_llm,
            llm_model=template.llm_model,
        )


_instance: DishService | None = None


def get_dish_service() -> DishService:
    if _instance is None:
        raise RuntimeError("DishService not initialized")
    return _instance


def init_dish_service() -> None:
    global _instance
    _instance = DishService()
