from pydantic import BaseModel, Field

from app.schema.dish import IngredientItem


class ShoppingMeal(BaseModel):
    day_of_week: int = Field(..., ge=1)  # day index in meal plan (1-based)
    foods: list["ShoppingFood"]


class ShoppingFood(BaseModel):
    food_name: str
    servings: float = 1
    ingredients: list[IngredientItem]


class GenerateShoppingRequest(BaseModel):
    week_start: str
    diner_count: int = 1
    meals: list[ShoppingMeal]


class ShoppingItem(BaseModel):
    name: str
    total_quantity: float
    unit: str
    purchase_quantity: float = 0
    purchase_unit: str = ""
    source_foods: list[str] = []


class ShoppingCategory(BaseModel):
    name: str
    sort_order: int
    items: list[ShoppingItem]


class GenerateShoppingResponse(BaseModel):
    week_start: str
    diner_count: int
    categories: list[ShoppingCategory]
