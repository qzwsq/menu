import logging

from fastapi import APIRouter

from app.config import get_config
from app.external.llm_client import get_llm
from app.schema.common import BaseResponse

router = APIRouter(tags=["health"])
logger = logging.getLogger(__name__)


@router.get("/api/health", response_model=BaseResponse[dict])
async def health_check():
    config = get_config()
    llm = get_llm()
    llm_available = False
    if llm.config.api_key:
        try:
            await llm.chat_completion(
                [{"role": "user", "content": "ping"}],
            )
            llm_available = True
        except Exception:
            logger.warning("LLM health check failed", exc_info=True)

    return BaseResponse.ok(data={
        "status": "ok",
        "version": config.version,
        "llm_available": llm_available,
    })
