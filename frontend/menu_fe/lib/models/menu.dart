class CreateMenuRequest {
  final String name;
  final int dinerCount;
  final String startDate;
  final String endDate;
  final bool generateShopping;
  final List<DayData> days;

  CreateMenuRequest({
    required this.name,
    required this.dinerCount,
    required this.startDate,
    required this.endDate,
    required this.generateShopping,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'diner_count': dinerCount,
        'start_date': startDate,
        'end_date': endDate,
        'generate_shopping': generateShopping,
        'days': days.map((d) => d.toJson()).toList(),
      };
}

class DayData {
  final String dayDate;
  final Map<String, dynamic> meals;

  DayData({required this.dayDate, required this.meals});

  Map<String, dynamic> toJson() => {
        'day_date': dayDate,
        'meals': meals,
      };
}

class CreateMenuResponse {
  final int id;
  final String name;
  final int dinerCount;
  final int daysCount;
  final int? shoppingListId;

  CreateMenuResponse({
    required this.id,
    required this.name,
    required this.dinerCount,
    required this.daysCount,
    this.shoppingListId,
  });

  factory CreateMenuResponse.fromJson(Map<String, dynamic> json) {
    return CreateMenuResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      dinerCount: json['diner_count'] as int,
      daysCount: json['days_count'] as int,
      shoppingListId: json['shopping_list_id'] as int?,
    );
  }
}

class MenuBrief {
  final int id;
  final String name;
  final int dinerCount;
  final String startDate;
  final String endDate;
  final bool hasShoppingList;
  final int? shoppingListId;

  MenuBrief({required this.id, required this.name, required this.dinerCount, required this.startDate, required this.endDate, required this.hasShoppingList, this.shoppingListId});

  factory MenuBrief.fromJson(Map<String, dynamic> json) {
    return MenuBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      dinerCount: json['diner_count'] as int,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      hasShoppingList: json['has_shopping_list'] as bool,
      shoppingListId: json['shopping_list_id'] as int?,
    );
  }
}

class MealItem {
  final int id;
  final String dayDate;
  final Map<String, dynamic> mealsData;

  MealItem({required this.id, required this.dayDate, required this.mealsData});

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as int,
      dayDate: json['day_date'] as String,
      mealsData: json['meals_data'] as Map<String, dynamic>,
    );
  }
}

class MenuDetail {
  final int id;
  final String name;
  final int dinerCount;
  final String startDate;
  final String endDate;
  final bool hasShoppingList;
  final int? shoppingListId;
  final List<MealItem> meals;

  MenuDetail({required this.id, required this.name, required this.dinerCount, required this.startDate, required this.endDate, required this.hasShoppingList, this.shoppingListId, required this.meals});

  factory MenuDetail.fromJson(Map<String, dynamic> json) {
    return MenuDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      dinerCount: json['diner_count'] as int,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      hasShoppingList: json['has_shopping_list'] as bool,
      shoppingListId: json['shopping_list_id'] as int?,
      meals: (json['meals'] as List<dynamic>).cast<Map<String, dynamic>>().map((e) => MealItem.fromJson(e)).toList(),
    );
  }
}

class ShoppingListData {
  final int id;
  final int menuId;
  final int dinerCount;
  final String weekStart;
  final List<dynamic> categories;

  ShoppingListData({required this.id, required this.menuId, required this.dinerCount, required this.weekStart, required this.categories});

  factory ShoppingListData.fromJson(Map<String, dynamic> json) {
    return ShoppingListData(
      id: json['id'] as int,
      menuId: json['menu_id'] as int,
      dinerCount: json['diner_count'] as int,
      weekStart: json['week_start'] as String,
      categories: json['categories'] as List<dynamic>,
    );
  }
}

class ShoppingBrief {
  final int id;
  final int menuId;
  final String menuName;
  final int dinerCount;
  final String weekStart;
  final List<dynamic> categories;

  ShoppingBrief({required this.id, required this.menuId, required this.menuName, required this.dinerCount, required this.weekStart, required this.categories});

  factory ShoppingBrief.fromJson(Map<String, dynamic> json) {
    return ShoppingBrief(
      id: json['id'] as int,
      menuId: json['menu_id'] as int,
      menuName: json['menu_name'] as String,
      dinerCount: json['diner_count'] as int,
      weekStart: json['week_start'] as String,
      categories: json['categories'] as List<dynamic>,
    );
  }
}
