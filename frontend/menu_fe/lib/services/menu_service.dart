import '../models/menu.dart';
import 'api_client.dart';

class MenuService {
  static final MenuService _instance = MenuService._();
  factory MenuService() => _instance;

  final _client = ApiClient();

  MenuService._();

  Future<CreateMenuResponse?> create({
    required String name,
    required int dinerCount,
    required String startDate,
    required String endDate,
    required bool generateShopping,
    required List<Map<String, dynamic>> daysMeals,
  }) async {
    try {
      final days = daysMeals
          .map((d) => DayData(dayDate: d['day_date'] as String, meals: d['meals'] as Map<String, dynamic>))
          .toList();

      final req = CreateMenuRequest(
        name: name,
        dinerCount: dinerCount,
        startDate: startDate,
        endDate: endDate,
        generateShopping: generateShopping,
        days: days,
      );

      final response = await _client.post<Map<String, dynamic>>(
        '/api/menus',
        data: req.toJson(),
      );

      final data = response.data;
      if (data == null) return null;
      final code = data['code'] as int;
      if (code != 0) return null;
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return null;
      return CreateMenuResponse.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Future<List<MenuBrief>> list() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/menus');
      final data = response.data;
      if (data == null) return [];
      final code = data['code'] as int;
      if (code != 0) return [];
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return [];
      final items = (payload['items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>()
          .map((json) => MenuBrief.fromJson(json))
          .toList();
      return items ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<MenuDetail?> detail(int menuId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/menus/$menuId');
      final data = response.data;
      if (data == null) return null;
      final code = data['code'] as int;
      if (code != 0) return null;
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return null;
      return MenuDetail.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Future<bool> delete(int menuId, {bool deleteShopping = false}) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        '/api/menus/$menuId',
        queryParameters: {'delete_shopping': deleteShopping},
      );
      final data = response.data;
      if (data == null || (data['code'] as int) != 0) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ShoppingListData?> getShoppingList(int menuId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/shopping/$menuId');
      final data = response.data;
      if (data == null) return null;
      final code = data['code'] as int;
      if (code != 0) return null;
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return null;
      return ShoppingListData.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Future<List<ShoppingBrief>> listAllShopping() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/shopping');
      final data = response.data;
      if (data == null) return [];
      final code = data['code'] as int;
      if (code != 0) return [];
      final payload = data['data'] as Map<String, dynamic>?;
      if (payload == null) return [];
      final items = (payload['items'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>()
          .map((json) => ShoppingBrief.fromJson(json))
          .toList();
      return items ?? [];
    } catch (_) {
      return [];
    }
  }
}
