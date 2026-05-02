class Food {
  final String id;
  final String name;
  final String foodType;

  const Food({
    required this.id,
    required this.name,
    required this.foodType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Food && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MealSlot {
  List<Food> staples;
  List<Food> dishes;
  List<Food> drinks;
  List<Food> fruits;

  MealSlot({
    List<Food>? staples,
    List<Food>? dishes,
    List<Food>? drinks,
    List<Food>? fruits,
  })  : staples = staples ?? [],
        dishes = dishes ?? [],
        drinks = drinks ?? [],
        fruits = fruits ?? [];

  void addFood(Food food) {
    switch (food.foodType) {
      case 'staple':
        staples = [...staples, food];
      case 'drink':
        drinks = [...drinks, food];
      case 'fruit':
        fruits = [...fruits, food];
      default:
        dishes = [...dishes, food];
    }
  }

  void removeFood(String id) {
    staples = staples.where((f) => f.id != id).toList();
    dishes = dishes.where((f) => f.id != id).toList();
    drinks = drinks.where((f) => f.id != id).toList();
    fruits = fruits.where((f) => f.id != id).toList();
  }

  int get totalCount =>
      staples.length + dishes.length + drinks.length + fruits.length;
}
