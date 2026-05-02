"""create dish_templates

Revision ID: 22c932291b81
Revises:
Create Date: 2026-05-02 22:31:19.230233

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "22c932291b81"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "dish_templates",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("food_type", sa.String(length=20), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=True),
        sa.Column("ingredients", sa.JSON(), nullable=False),
        sa.Column("nutrition", sa.JSON(), nullable=False),
        sa.Column("created_by_llm", sa.Boolean(), nullable=False),
        sa.Column("llm_model", sa.String(length=100), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
    )


def downgrade() -> None:
    op.drop_table("dish_templates")
