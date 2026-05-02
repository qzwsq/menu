from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session_dep
from app.schema.common import BaseResponse, PaginatedData
from app.schema.menu import (
    CreateMenuRequest,
    CreateMenuResponse,
    MenuBrief,
    MenuDetail,
)
from app.service.menu_service import get_menu_service

router = APIRouter(prefix="/api/menus", tags=["menus"])


@router.post("", response_model=BaseResponse[CreateMenuResponse])
async def create_menu(
    req: CreateMenuRequest,
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_menu_service()
    result = await svc.create(req)
    return BaseResponse.ok(data=result)


@router.get("", response_model=BaseResponse[PaginatedData[MenuBrief]])
async def list_menus(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_menu_service()
    items, total = await svc.list_menus(page=page, page_size=page_size)
    return BaseResponse.ok(data=PaginatedData(
        items=items, total=total, page=page, page_size=page_size
    ))


@router.get("/{menu_id}", response_model=BaseResponse[MenuDetail])
async def get_menu(
    menu_id: int,
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_menu_service()
    result = await svc.get_menu(menu_id)
    if result is None:
        raise HTTPException(status_code=404, detail="食谱不存在")
    return BaseResponse.ok(data=result)


@router.delete("/{menu_id}", response_model=BaseResponse[bool])
async def delete_menu(
    menu_id: int,
    delete_shopping: bool = Query(False),
    session: AsyncSession = Depends(get_session_dep),
):
    svc = get_menu_service()
    ok = await svc.delete_menu(menu_id, delete_shopping=delete_shopping)
    if not ok:
        raise HTTPException(status_code=404, detail="食谱不存在")
    return BaseResponse.ok(data=True)
