class DishTemplateItem {
  final String id;
  final String name;
  final String foodType;
  final String? category;
  final List<IngredientItem> ingredients;
  final NutritionData nutrition;
  final bool createdByLlm;
  final String? llmModel;

  DishTemplateItem({
    required this.id,
    required this.name,
    required this.foodType,
    this.category,
    required this.ingredients,
    required this.nutrition,
    required this.createdByLlm,
    this.llmModel,
  });

  factory DishTemplateItem.fromJson(Map<String, dynamic> json) {
    return DishTemplateItem(
      id: json['id'] as String,
      name: json['name'] as String,
      foodType: json['food_type'] as String,
      category: json['category'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => IngredientItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nutrition:
          NutritionData.fromJson(json['nutrition'] as Map<String, dynamic>),
      createdByLlm: json['created_by_llm'] as bool? ?? false,
      llmModel: json['llm_model'] as String?,
    );
  }
}

class IngredientItem {
  final String name;
  final double quantity;
  final String unit;

  IngredientItem({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}

class NutritionData {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sodium;

  NutritionData({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sodium,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });
}

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});
}
