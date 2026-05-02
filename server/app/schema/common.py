from typing import Any, Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class BaseResponse(BaseModel, Generic[T]):
    code: int = 0
    message: str = "success"
    data: T | None = None

    @classmethod
    def ok(cls, data: T = None, message: str = "success") -> "BaseResponse[T]":
        return cls(code=0, message=message, data=data)

    @classmethod
    def error(cls, code: int, message: str) -> "BaseResponse":
        return cls(code=code, message=message, data=None)


class PaginatedData(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    page_size: int
