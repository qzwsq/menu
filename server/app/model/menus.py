from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.model.dish_template import Base


class Menu(Base):
    __tablename__ = "menus"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    diner_count: Mapped[int] = mapped_column(Integer, default=1)
    start_date: Mapped[str] = mapped_column(String(10), nullable=False)
    end_date: Mapped[str] = mapped_column(String(10), nullable=False)
    has_shopping_list: Mapped[bool] = mapped_column(default=False)
    shopping_list_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp(),
    )


class MenuMeal(Base):
    __tablename__ = "menu_meals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    menu_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("menus.id", ondelete="CASCADE"), nullable=False
    )
    day_date: Mapped[str] = mapped_column(String(10), nullable=False)
    meals_data: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp(),
    )
