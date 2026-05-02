from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.model.dish_template import Base


class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    menu_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("menus.id", ondelete="CASCADE"), nullable=False
    )
    diner_count: Mapped[int] = mapped_column(Integer, default=1)
    week_start: Mapped[str] = mapped_column(String(10), nullable=False)
    categories: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.current_timestamp()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp(),
    )
