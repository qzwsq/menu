from sqlalchemy import select, func

from app.database import get_session
from app.model.dish_template import DishTemplate


class DishTemplateRepo:
    @property
    def session(self):
        return get_session()

    async def get_by_id(self, template_id: str) -> DishTemplate | None:
        return await self.session.get(DishTemplate, template_id)

    async def get_by_name(self, name: str) -> DishTemplate | None:
        result = await self.session.execute(
            select(DishTemplate).where(DishTemplate.name == name)
        )
        return result.scalar_one_or_none()

    async def list_templates(
        self,
        keyword: str | None = None,
        food_type: str | None = None,
        category: str | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[DishTemplate], int]:
        query = select(DishTemplate)
        count_query = select(func.count(DishTemplate.id))

        if keyword:
            query = query.where(DishTemplate.name.contains(keyword))
            count_query = count_query.where(DishTemplate.name.contains(keyword))
        if food_type:
            query = query.where(DishTemplate.food_type == food_type)
            count_query = count_query.where(DishTemplate.food_type == food_type)
        if category:
            query = query.where(DishTemplate.category == category)
            count_query = count_query.where(DishTemplate.category == category)

        total = (await self.session.execute(count_query)).scalar()

        query = query.offset((page - 1) * page_size).limit(page_size)
        result = await self.session.execute(query)
        items = list(result.scalars().all())

        return items, total

    async def create(self, template: DishTemplate) -> DishTemplate:
        self.session.add(template)
        await self.session.flush()
        return template

    async def save(self, template: DishTemplate) -> DishTemplate:
        template = await self.session.merge(template)
        await self.session.flush()
        return template

    async def search(self, q: str, limit: int = 20) -> list[DishTemplate]:
        result = await self.session.execute(
            select(DishTemplate)
            .where(DishTemplate.name.contains(q))
            .limit(limit)
        )
        return list(result.scalars().all())


_instance: DishTemplateRepo | None = None


def get_dish_repo() -> DishTemplateRepo:
    if _instance is None:
        raise RuntimeError("DishTemplateRepo not initialized")
    return _instance


def init_dish_repo() -> None:
    global _instance
    _instance = DishTemplateRepo()
