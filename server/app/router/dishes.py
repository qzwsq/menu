from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session_dep
from app.schema.common import BaseResponse, PaginatedData
from app.schema.dish import (
    AddDishRequest,
    DishTemplateResponse,
)
from app.service.dish_service import get_dish_service

router = APIRouter(prefix="/api/dishes", tags=["dishes"])


@router.post("/add", response_model=BaseResponse[DishTemplateResponse])
async def add_dish(
    req: AddDishRequest,
    session: AsyncSession = Depends(get_session_dep),
):
    try:
        svc = get_dish_service()
        result = await svc.add_dish(req)
        return BaseResponse.ok(data=result)
    except Exception as e:
        return BaseResponse.error(code=502, message=f"添加菜品失败: {str(e)}")


@router.get("", response_model=BaseResponse[PaginatedData[DishTemplateResponse]])
async def list_dishes(
    keyword: str | None = Query(None),
    food_type: str | None = Query(None),
    category: str | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(200, ge=1, le=300),
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_dish_service()
    items, total = await svc.list_templates(
        keyword=keyword,
        food_type=food_type,
        category=category,
        page=page,
        page_size=page_size,
    )
    return BaseResponse.ok(data=PaginatedData(
        items=items, total=total, page=page, page_size=page_size
    ))


@router.get("/search", response_model=BaseResponse[list[DishTemplateResponse]])
async def search_dishes(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=100),
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_dish_service()
    items = await svc.search(q, limit=limit)
    return BaseResponse.ok(data=items)


@router.get("/{dish_id}", response_model=BaseResponse[DishTemplateResponse])
async def get_dish(
    dish_id: str,
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_dish_service()
    result = await svc.get_template(dish_id)
    if result is None:
        raise HTTPException(status_code=404, detail="菜品模板不存在")
    return BaseResponse.ok(data=result)
