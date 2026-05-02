import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import init_config, load_config
from app.database import close_db, init_db
from app.external.llm_client import init_llm
from app.repository.dish_template_repo import init_dish_repo
from app.repository.menu_repo import init_menu_repo
from app.repository.shopping_repo import init_shopping_repo
from app.router.dishes import router as dishes_router
from app.router.health import router as health_router
from app.router.menus import router as menus_router
from app.router.nutrition import router as nutrition_router
from app.router.shopping import router as shopping_router
from app.service.dish_service import init_dish_service
from app.service.menu_service import init_menu_service
from app.service.nutrition_service import init_nutrition_service


def create_app() -> FastAPI:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(name)s] %(levelname)s %(message)s",
    )

    config = load_config()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
        await init_db(config)
        init_config(config)
        init_llm(config.llm)
        init_dish_repo()
        init_menu_repo()
        init_shopping_repo()
        init_dish_service()
        init_menu_service()
        init_nutrition_service()
        yield
        await close_db()

    app = FastAPI(
        title="Menu API",
        version=config.version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health_router)
    app.include_router(dishes_router)
    app.include_router(menus_router)
    app.include_router(nutrition_router)
    app.include_router(shopping_router)

    return app


app = create_app()
