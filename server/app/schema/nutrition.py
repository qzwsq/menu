from pydantic import BaseModel, Field

from app.schema.dish import NutritionData


class MealFood(BaseModel):
    food_name: str
    food_type: str
    servings: float = 1
    nutrition: NutritionData


class MealEntry(BaseModel):
    day_of_week: int = Field(..., ge=1)  # day index in meal plan (1-based)
    meal_order: str = "lunch"
    foods: list[MealFood]


class AnalyzeNutritionRequest(BaseModel):
    week_start: str
    diner_count: int = 1
    meals: list[MealEntry]


class DailyNutrition(NutritionData):
    pass


class AnalyzeNutritionResponse(BaseModel):
    daily_averages: NutritionData
    daily_breakdown: list[dict]


class AssessNutritionRequest(BaseModel):
    nutrition_data: AnalyzeNutritionResponse
    diner_count: int = 1


class AssessNutritionResponse(BaseModel):
    summary: str
    highlights: list[str]
    risks: list[str]
    recommendations: list[str]
    generated_by_llm: bool = True
