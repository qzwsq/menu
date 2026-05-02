from __future__ import annotations

from pydantic import BaseModel, Field


class DayMealData(BaseModel):
    day_date: str
    meals: dict


class CreateMenuRequest(BaseModel):
    name: str
    diner_count: int = Field(default=1, ge=1)
    start_date: str
    end_date: str
    generate_shopping: bool = False
    days: list[DayMealData]


class MenuBrief(BaseModel):
    id: int
    name: str
    diner_count: int
    start_date: str
    end_date: str
    has_shopping_list: bool
    shopping_list_id: int | None
    created_at: str | None = None

    class Config:
        from_attributes = True


class MealItem(BaseModel):
    id: int
    day_date: str
    meals_data: dict


class MenuDetail(BaseModel):
    id: int
    name: str
    diner_count: int
    start_date: str
    end_date: str
    has_shopping_list: bool
    shopping_list_id: int | None
    meals: list[MealItem]


class CreateMenuResponse(BaseModel):
    id: int
    name: str
    diner_count: int
    days_count: int
    shopping_list_id: int | None

