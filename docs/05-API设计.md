# 05 - API 设计

## 5.1 通用规范

- **Base URL**: `http://{host}:{port}/api`
- **Content-Type**: `application/json`
- **响应格式**:

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

错误码：
| code | 说明 |
|------|------|
| 0 | 成功 |
| 400 | 请求参数错误 |
| 500 | 服务端错误 |
| 502 | LLM调用失败 |

---

## 5.2 菜品管理 API

### 5.2.1 LLM生成菜品配置

```
POST /api/dishes/generate
```

**Request:**
```json
{
  "name": "宫保鸡丁",
  "category": "荤菜",
  "existing_ingredients": []
}
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "name": "宫保鸡丁",
    "food_type": "dish",
    "category": "荤菜",
    "ingredients": [
      {"name": "鸡胸肉", "quantity": 300, "unit": "g"},
      {"name": "花生米", "quantity": 50, "unit": "g"},
      {"name": "黄瓜", "quantity": 100, "unit": "g"},
      {"name": "干辣椒", "quantity": 10, "unit": "g"},
      {"name": "葱", "quantity": 20, "unit": "g"},
      {"name": "姜", "quantity": 10, "unit": "g"},
      {"name": "蒜", "quantity": 10, "unit": "g"}
    ],
    "nutrition": {
      "calories": 350,
      "protein": 28,
      "fat": 18,
      "carbs": 15,
      "fiber": 3,
      "sodium": 800
    },
    "generated_by_llm": true
  }
}
```

### 5.2.2 获取菜品模板列表

```
GET /api/dishes?keyword=&food_type=&category=&page=1&page_size=20
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "items": [...],
    "total": 50,
    "page": 1,
    "page_size": 20
  }
}
```

### 5.2.3 获取菜品详情

```
GET /api/dishes/{id}
```

### 5.2.4 搜索菜品

```
GET /api/dishes/search?q=宫保
```

---

## 5.3 营养分析 API

### 5.3.1 分析周菜单营养

```
POST /api/nutrition/analyze
```

**Request:**
```json
{
  "week_start": "2026-05-04",
  "diner_count": 2,
  "meals": [
    {
      "day_of_week": 1,
      "meal_order": "lunch",
      "foods": [
        {
          "food_name": "米饭",
          "food_type": "staple",
          "servings": 2,
          "nutrition": {
            "calories": 200,
            "protein": 4,
            "fat": 1,
            "carbs": 44,
            "fiber": 1,
            "sodium": 5
          }
        },
        {
          "food_name": "宫保鸡丁",
          "food_type": "dish",
          "servings": 1,
          "nutrition": {
            "calories": 350,
            "protein": 28,
            "fat": 18,
            "carbs": 15,
            "fiber": 3,
            "sodium": 800
          }
        }
      ]
    }
  ]
}
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "daily_averages": {
      "calories": 2100,
      "protein": 80,
      "fat": 65,
      "carbs": 280,
      "fiber": 25,
      "sodium": 3200
    },
    "daily_breakdown": [
      {"day": 1, "calories": 2200, "protein": 85, "fat": 70, "carbs": 290, "fiber": 28, "sodium": 3400},
      {"day": 2, "calories": 2000, "protein": 75, "fat": 60, "carbs": 270, "fiber": 22, "sodium": 3000}
    ]
  }
}
```

### 5.3.2 生成营养评估报告

```
POST /api/nutrition/assess
```

**Request:**
```json
{
  "nutrition_data": {
    "daily_averages": { ... },
    "daily_breakdown": [ ... ]
  },
  "diner_count": 2
}
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "summary": "本周营养摄入基本均衡，日均热量摄入适中...",
    "highlights": [
      "蛋白质摄入充足，日均80g",
      "周三脂肪摄入偏高，建议减少油炸食品"
    ],
    "risks": [
      "周五碳水化合物摄入偏低"
    ],
    "recommendations": [
      "建议增加蔬菜比例，提高膳食纤维摄入",
      "减少高盐菜品，控制钠摄入"
    ],
    "generated_by_llm": true
  }
}
```

---

## 5.4 采购清单 API

### 5.4.1 生成采购清单

```
POST /api/shopping/generate
```

**Request:**
```json
{
  "week_start": "2026-05-04",
  "diner_count": 2,
  "meals": [
    {
      "day_of_week": 1,
      "foods": [
        {
          "food_name": "宫保鸡丁",
          "servings": 1,
          "ingredients": [
            {"name": "鸡胸肉", "quantity": 300, "unit": "g"},
            {"name": "花生米", "quantity": 50, "unit": "g"}
          ]
        }
      ]
    }
  ]
}
```

**Response:** 后端自动分类，按分类分组返回，前端按分组渲染Todo清单

```json
{
  "code": 0,
  "data": {
    "week_start": "2026-05-04",
    "diner_count": 2,
    "categories": [
      {
        "name": "肉类",
        "sort_order": 1,
        "items": [
          {
            "name": "鸡胸肉",
            "total_quantity": 600,
            "unit": "g",
            "source_foods": ["宫保鸡丁", "香菇滑鸡"]
          },
          {
            "name": "猪肉",
            "total_quantity": 400,
            "unit": "g",
            "source_foods": ["鱼香肉丝"]
          }
        ]
      },
      {
        "name": "蔬菜",
        "sort_order": 2,
        "items": [
          {
            "name": "黄瓜",
            "total_quantity": 200,
            "unit": "g",
            "source_foods": ["宫保鸡丁", "凉拌黄瓜"]
          }
        ]
      }
    ]
  }
}
```

> 食材分类规则由后端Service层内置，无需用户配置。常见分类：肉类、水产、蔬菜、豆制品、干货、调料、主食。

---

## 5.5 系统 API

### 5.5.1 健康检查

```
GET /api/health
```

**Response:**
```json
{
  "code": 0,
  "data": {
    "status": "ok",
    "version": "1.0.0",
    "llm_available": true
  }
}
```
