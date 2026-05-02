from app.external.llm_client import get_llm
from app.schema.dish import NutritionData
from app.schema.nutrition import (
    AnalyzeNutritionRequest,
    AnalyzeNutritionResponse,
    AssessNutritionRequest,
    AssessNutritionResponse,
)

NUTRITION_ASSESS_PROMPT = """你是一个专业的营养师。根据提供的周菜单营养数据，进行全面的营养评估，给出总结、亮点、风险点和改善建议。

返回JSON格式：
{
  "summary": "整体营养评价总结",
  "highlights": ["亮点1", "亮点2"],
  "risks": ["风险点1"],
  "recommendations": ["改善建议1", "改善建议2"]
}
"""


class NutritionService:
    @property
    def llm(self):
        return get_llm()

    async def analyze(self, req: AnalyzeNutritionRequest) -> AnalyzeNutritionResponse:
        daily_totals: dict[int, dict[str, float]] = {}
        days_count = 0

        for meal in req.meals:
            day = meal.day_of_week
            if day not in daily_totals:
                daily_totals[day] = {}
                days_count += 1
            for food in meal.foods:
                factor = food.servings * req.diner_count
                for field in NutritionData.model_fields:
                    val = getattr(food.nutrition, field, 0) or 0
                    daily_totals[day][field] = (
                        daily_totals[day].get(field, 0) + val * factor
                    )

        daily_breakdown = []
        totals: dict[str, float] = {}
        for day in sorted(daily_totals.keys()):
            day_data = {"day": day, **daily_totals[day]}
            daily_breakdown.append(day_data)
            for field, val in daily_totals[day].items():
                totals[field] = totals.get(field, 0) + val

        days = days_count or 1
        daily_averages = NutritionData(
            **{field: round(totals.get(field, 0) / days, 1) for field in NutritionData.model_fields}
        )

        return AnalyzeNutritionResponse(
            daily_averages=daily_averages,
            daily_breakdown=daily_breakdown,
        )

    async def assess(self, req: AssessNutritionRequest) -> AssessNutritionResponse:
        averages = req.nutrition_data.daily_averages
        breakdown = req.nutrition_data.daily_breakdown

        user_prompt = f"""请评估以下周菜单营养数据：

每日平均值：{averages.model_dump()}
每日明细：{breakdown}
就餐人数：{req.diner_count}人"""

        result = await self.llm.generate_json(
            NUTRITION_ASSESS_PROMPT, user_prompt
        )

        return AssessNutritionResponse(
            summary=result.get("summary", ""),
            highlights=result.get("highlights", []),
            risks=result.get("risks", []),
            recommendations=result.get("recommendations", []),
            generated_by_llm=True,
        )


_instance: NutritionService | None = None


def get_nutrition_service() -> NutritionService:
    if _instance is None:
        raise RuntimeError("NutritionService not initialized")
    return _instance


def init_nutrition_service() -> None:
    global _instance
    _instance = NutritionService()
