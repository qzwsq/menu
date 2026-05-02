from app.database import get_session
from app.model.shopping_list import ShoppingList


class ShoppingRepo:
    @property
    def session(self):
        return get_session()

    async def create(
        self,
        menu_id: int,
        diner_count: int,
        week_start: str,
        categories: list[dict],
    ) -> ShoppingList:
        sl = ShoppingList(
            menu_id=menu_id,
            diner_count=diner_count,
            week_start=week_start,
            categories=categories,
        )
        self.session.add(sl)
        await self.session.flush()
        return sl

    async def get_by_menu(self, menu_id: int) -> ShoppingList | None:
        from sqlalchemy import select

        result = await self.session.execute(
            select(ShoppingList).where(ShoppingList.menu_id == menu_id)
        )
        return result.scalar_one_or_none()

    async def get_by_id(self, sl_id: int) -> ShoppingList | None:
        return await self.session.get(ShoppingList, sl_id)

    async def delete(self, sl_id: int) -> bool:
        sl = await self.get_by_id(sl_id)
        if sl is None:
            return False
        await self.session.delete(sl)
        await self.session.flush()
        return True


    async def list_all(
        self, page: int = 1, page_size: int = 20
    ) -> tuple[list[dict], int]:
        from sqlalchemy import func, select

        from app.model.menus import Menu

        stmt = (
            select(ShoppingList.id, ShoppingList.menu_id, ShoppingList.diner_count,
                   ShoppingList.week_start, ShoppingList.created_at,
                   ShoppingList.categories, Menu.name.label("menu_name"))
            .join(Menu, ShoppingList.menu_id == Menu.id)
            .order_by(ShoppingList.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        count_stmt = select(func.count(ShoppingList.id))

        total = (await self.session.execute(count_stmt)).scalar()
        rows = (await self.session.execute(stmt)).all()

        items = [
            {
                "id": row.id,
                "menu_id": row.menu_id,
                "menu_name": row.menu_name,
                "diner_count": row.diner_count,
                "week_start": row.week_start,
                "categories": row.categories,
                "created_at": row.created_at.isoformat() if row.created_at else None,
            }
            for row in rows
        ]
        return items, total


_instance: ShoppingRepo | None = None


def get_shopping_repo() -> ShoppingRepo:
    if _instance is None:
        raise RuntimeError("ShoppingRepo not initialized")
    return _instance


def init_shopping_repo() -> None:
    global _instance
    _instance = ShoppingRepo()
