import json
import logging
from typing import Any

from openai import AsyncOpenAI

from app.config import LLMConfig

logger = logging.getLogger(__name__)

_instance: "LLMClient | None" = None


def init_llm(config: LLMConfig) -> None:
    global _instance
    _instance = LLMClient(config)


def get_llm() -> "LLMClient":
    if _instance is None:
        raise RuntimeError("LLMClient not initialized — call init_llm first")
    return _instance


class LLMClient:
    def __init__(self, config: LLMConfig):
        self.config = config
        self.client = AsyncOpenAI(
            api_key=config.api_key,
            base_url=config.api_base,
        )

    async def chat_completion(
        self,
        messages: list[dict[str, str]],
        response_format: dict[str, Any] | None = None,
    ) -> str:
        kwargs: dict[str, Any] = dict(
            model=self.config.model,
            messages=messages,
            temperature=self.config.temperature,
            max_tokens=self.config.max_tokens,
        )
        if response_format:
            kwargs["response_format"] = response_format

        msg_summary = [
            {"role": m["role"], "len": len(m["content"])}
            for m in messages
        ]
        logger.info("[LLM] request model=%s messages=%s", self.config.model, msg_summary)

        response = await self.client.chat.completions.create(**kwargs)
        content = response.choices[0].message.content or ""

        logger.info(
            "[LLM] response model=%s usage=%s finish_reason=%s content_len=%d content_preview=%s",
            response.model,
            response.usage,
            response.choices[0].finish_reason,
            len(content),
            content[:200],
        )
        return content

    async def generate_json(
        self,
        system_prompt: str,
        user_prompt: str,
    ) -> dict[str, Any]:
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        content = await self.chat_completion(
            messages,
            response_format={"type": "json_object"},
        )
        return json.loads(content)

    async def generate_text(
        self,
        system_prompt: str,
        user_prompt: str,
    ) -> str:
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ]
        return await self.chat_completion(messages)
