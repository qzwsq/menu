from fastapi import APIRouter

from app.schema.common import BaseResponse
from app.schema.nutrition import (
    AnalyzeNutritionRequest,
    AnalyzeNutritionResponse,
    AssessNutritionRequest,
    AssessNutritionResponse,
)
from app.service.nutrition_service import get_nutrition_service

router = APIRouter(prefix="/api/nutrition", tags=["nutrition"])


@router.post("/analyze", response_model=BaseResponse[AnalyzeNutritionResponse])
async def analyze_nutrition(req: AnalyzeNutritionRequest):
    svc = get_nutrition_service()
    result = await svc.analyze(req)
    return BaseResponse.ok(data=result)


@router.post("/assess", response_model=BaseResponse[AssessNutritionResponse])
async def assess_nutrition(req: AssessNutritionRequest):
    try:
        svc = get_nutrition_service()
        result = await svc.assess(req)
        return BaseResponse.ok(data=result)
    except Exception as e:
        return BaseResponse.error(code=502, message=f"LLM调用失败: {str(e)}")
