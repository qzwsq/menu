from pydantic import BaseModel, Field


class IngredientItem(BaseModel):
    name: str
    quantity: float
    unit: str


class NutritionData(BaseModel):
    calories: float = 0
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    fiber: float = 0
    sodium: float = 0


class DishTemplateResponse(BaseModel):
    id: str
    name: str
    food_type: str
    category: str | None = None
    ingredients: list[IngredientItem]
    nutrition: NutritionData
    created_by_llm: bool = False
    llm_model: str | None = None

    class Config:
        from_attributes = True


class AddDishRequest(BaseModel):
    name: str = Field(..., description="菜品名称")
