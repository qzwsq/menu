import '../models/dish_template.dart';
import '../models/food.dart';
import 'api_client.dart';

class DishService {
  static final DishService _instance = DishService._();
  factory DishService() => _instance;

  final _client = ApiClient();

  DishService._();

  Future<List<Food>> fetchDishes({
    String? keyword,
    String? foodType,
    String? category,
  }) async {
    const pageSize = 300;
    final allItems = <Food>[];

    try {
      int page = 1;
      int total = 0;

      while (true) {
        final query = <String, dynamic>{
          'page': page,
          'page_size': pageSize,
        };
        if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
        if (foodType != null) query['food_type'] = foodType;
        if (category != null) query['category'] = category;

        final response = await _client.get<Map<String, dynamic>>(
          '/api/dishes',
          queryParameters: query,
        );

        final data = response.data;
        if (data == null) break;

        final code = data['code'] as int;
        if (code != 0) break;

        final payload = data['data'] as Map<String, dynamic>?;
        if (payload == null) break;

        total = payload['total'] as int? ?? 0;

        final items = (payload['items'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map((json) => DishTemplateItem.fromJson(json))
            .map(_toFood)
            .toList();

        if (items != null) {
          allItems.addAll(items);
        }

        if (allItems.length >= total) break;
        page++;
      }
    } catch (_) {
      // ignore network errors, return whatever was fetched
    }

    return allItems;
  }

  Future<DishTemplateItem?> addDish(String name) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/dishes/add',
        data: {'name': name},
      );
      final data = response.data;
      if (data == null) return null;
      final code = data['code'] as int;
      if (code != 0) return null;
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return null;
      return DishTemplateItem.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Food _toFood(DishTemplateItem item) {
    return Food(
      id: item.id,
      name: item.name,
      foodType: item.foodType,
    );
  }
}
