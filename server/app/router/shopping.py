from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session_dep
from app.repository.shopping_repo import get_shopping_repo
from app.schema.common import BaseResponse, PaginatedData
from app.schema.shopping import GenerateShoppingRequest, GenerateShoppingResponse
from app.service.shopping_service import ShoppingService

router = APIRouter(prefix="/api/shopping", tags=["shopping"])


@router.get("", response_model=BaseResponse[PaginatedData[dict]])
async def list_shopping(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    session: AsyncSession = Depends(get_session_dep),
):
    repo = get_shopping_repo()
    items, total = await repo.list_all(page=page, page_size=page_size)
    return BaseResponse.ok(data=PaginatedData(
        items=items, total=total, page=page, page_size=page_size
    ))


@router.post("/generate", response_model=BaseResponse[GenerateShoppingResponse])
async def generate_shopping(req: GenerateShoppingRequest):
    svc = ShoppingService()
    result = await svc.generate(req)
    return BaseResponse.ok(data=result)


@router.get("/{menu_id}", response_model=BaseResponse[dict])
async def get_shopping_by_menu(
    menu_id: int,
    session: AsyncSession = Depends(get_session_dep),
):
    repo = get_shopping_repo()
    sl = await repo.get_by_menu(menu_id)
    if sl is None:
        raise HTTPException(status_code=404, detail="采购清单不存在")
    return BaseResponse.ok(data={
        "id": sl.id,
        "menu_id": sl.menu_id,
        "diner_count": sl.diner_count,
        "week_start": sl.week_start,
        "categories": sl.categories,
    })
