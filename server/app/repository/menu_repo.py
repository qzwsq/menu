from sqlalchemy import func, select

from app.database import get_session
from app.model.menus import Menu, MenuMeal


class MenuRepo:
    @property
    def session(self):
        return get_session()

    async def create_menu(
        self,
        name: str,
        diner_count: int,
        start_date: str,
        end_date: str,
        has_shopping_list: bool = False,
        shopping_list_id: int | None = None,
    ) -> Menu:
        menu = Menu(
            name=name,
            diner_count=diner_count,
            start_date=start_date,
            end_date=end_date,
            has_shopping_list=has_shopping_list,
            shopping_list_id=shopping_list_id,
        )
        self.session.add(menu)
        await self.session.flush()
        return menu

    async def create_meals(self, menu_id: int, days: list[dict]) -> list[MenuMeal]:
        meals = [
            MenuMeal(
                menu_id=menu_id,
                day_date=d["day_date"],
                meals_data=d["meals"],
            )
            for d in days
        ]
        self.session.add_all(meals)
        await self.session.flush()
        return meals

    async def get_menu(self, menu_id: int) -> Menu | None:
        return await self.session.get(Menu, menu_id)

    async def get_meals(self, menu_id: int) -> list[MenuMeal]:
        result = await self.session.execute(
            select(MenuMeal)
            .where(MenuMeal.menu_id == menu_id)
            .order_by(MenuMeal.day_date)
        )
        return list(result.scalars().all())

    async def list_menus(
        self, page: int = 1, page_size: int = 20
    ) -> tuple[list[Menu], int]:
        total = (
            await self.session.execute(select(func.count(Menu.id)))
        ).scalar()

        result = await self.session.execute(
            select(Menu)
            .order_by(Menu.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return list(result.scalars().all()), total

    async def update_menu(
        self,
        menu_id: int,
        name: str | None = None,
        diner_count: int | None = None,
        has_shopping_list: bool | None = None,
        shopping_list_id: int | None = None,
    ) -> Menu | None:
        menu = await self.get_menu(menu_id)
        if menu is None:
            return None
        if name is not None:
            menu.name = name
        if diner_count is not None:
            menu.diner_count = diner_count
        if has_shopping_list is not None:
            menu.has_shopping_list = has_shopping_list
        if shopping_list_id is not None:
            menu.shopping_list_id = shopping_list_id
        await self.session.flush()
        return menu

    async def delete_menu(self, menu_id: int) -> bool:
        menu = await self.get_menu(menu_id)
        if menu is None:
            return False
        await self.session.delete(menu)
        await self.session.flush()
        return True


_instance: MenuRepo | None = None


def get_menu_repo() -> MenuRepo:
    if _instance is None:
        raise RuntimeError("MenuRepo not initialized")
    return _instance


def init_menu_repo() -> None:
    global _instance
    _instance = MenuRepo()
