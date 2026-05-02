import re
from pathlib import Path

_PROMPT_DIR = Path(__file__).parent.parent.parent / "resource" / "prompt"
_VAR_PATTERN = re.compile(r"\{\{(\w+)\}\}")


def _replace(content: str, **kwargs: str) -> str:
    return _VAR_PATTERN.sub(lambda m: kwargs.get(m.group(1), m.group(0)), content)


def render_prompt(filename: str, **kwargs: str) -> tuple[str, str]:
    raw = (_PROMPT_DIR / filename).read_text(encoding="utf-8").strip()
    parts = raw.split("\n---\n")
    if len(parts) != 2:
        raise ValueError(
            f"Prompt file {filename} must contain exactly one '---' separator"
        )
    system, user = parts
    return _replace(system.strip(), **kwargs), _replace(user.strip(), **kwargs)
