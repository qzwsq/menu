from contextvars import ContextVar

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import AppConfig

engine = None
async_session_factory: async_sessionmaker[AsyncSession] | None = None

_current_session: ContextVar[AsyncSession | None] = ContextVar(
    "session", default=None
)


async def init_db(config: AppConfig) -> None:
    global engine, async_session_factory
    engine = create_async_engine(config.db.url, echo=config.db.echo)
    async_session_factory = async_sessionmaker(engine, expire_on_commit=False)


def _set_session(session: AsyncSession) -> None:
    _current_session.set(session)


def get_session() -> AsyncSession:
    s = _current_session.get()
    if s is None:
        raise RuntimeError("No session set — is get_session dependency active?")
    return s


async def get_session_dep() -> AsyncSession:
    async with async_session_factory() as session:
        _set_session(session)
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def close_db() -> None:
    if engine:
        await engine.dispose()
