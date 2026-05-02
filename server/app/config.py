from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel


class LLMConfig(BaseModel):
    provider: str = "deepseek"
    api_key: str = "xxx"
    api_base: str = "https://api.deepseek.com"
    model: str = "deepseek-v4-flash"
    temperature: float = 0.7
    max_tokens: int = 4096


class DBConfig(BaseModel):
    host: str = "127.0.0.1"
    port: int = 3306
    user: str = "root"
    password: str = ""
    database: str = "menu"
    echo: bool = False

    @property
    def url(self) -> str:
        return f"mysql+aiomysql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"


class AppConfig(BaseModel):
    version: str = "1.0.0"
    llm: LLMConfig = LLMConfig()
    db: DBConfig = DBConfig()


def load_config(config_path: Optional[str] = None) -> AppConfig:
    if config_path is None:
        config_path = Path(__file__).parent.parent / "config.yaml"

    path = Path(config_path)
    if not path.exists():
        return AppConfig()

    with open(path, "r") as f:
        data = yaml.safe_load(f) or {}

    return AppConfig(**data)


_config: AppConfig | None = None


def init_config(config: AppConfig) -> None:
    global _config
    _config = config


def get_config() -> AppConfig:
    if _config is None:
        raise RuntimeError("Config not initialized — call init_config first")
    return _config
