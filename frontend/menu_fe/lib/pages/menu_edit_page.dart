import 'package:flutter/material.dart';

import '../models/food.dart';
import '../services/dish_service.dart';
import '../services/menu_service.dart';

class MenuEditPage extends StatefulWidget {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final VoidCallback? onBack;

  const MenuEditPage({
    super.key,
    required this.rangeStart,
    required this.rangeEnd,
    this.onBack,
  });

  @override
  State<MenuEditPage> createState() => _MenuEditPageState();
}

class _MenuEditPageState extends State<MenuEditPage> {
  int _dinerCount = 2;
  int _currentDay = 0;
  final ScrollController _scrollController = ScrollController();

  final _meals = <int, Map<String, MealSlot>>{};
  List<Food> _allFoods = [];

  static const _mealOrders = ['fruit', 'breakfast', 'lunch', 'dinner'];
  static const _mealLabels = ['水果', '早饭', '午饭', '晚饭'];
  static const _mealIcons = [
    Icons.apple,
    Icons.wb_sunny_outlined,
    Icons.wb_cloudy_outlined,
    Icons.nightlight_outlined,
  ];
  static const _dayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  static const _cardWidth = 280.0;
  static const _scrollPadding = 8.0;
  static const _foodDisplayHeight = 62.0;

  @override
  void initState() {
    super.initState();
    final days = widget.rangeEnd.difference(widget.rangeStart).inDays + 1;
    for (int d = 0; d < days; d++) {
      _meals[d + 1] = {
        for (final order in _mealOrders) order: MealSlot(),
      };
    }
    _scrollController.addListener(_onScroll);
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    final api = await DishService().fetchDishes();
    if (!mounted) return;
    setState(() => _allFoods = api);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  int get _totalDays =>
      widget.rangeEnd.difference(widget.rangeStart).inDays + 1;

  String _formatDay(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset =
        (_scrollController.offset - _scrollPadding).clamp(0.0, double.infinity);
    final idx = (offset / _cardWidth).round();
    if (idx != _currentDay && idx >= 0 && idx < _totalDays) {
      setState(() => _currentDay = idx);
    }
  }

  void _scrollToDay(int index) {
    final target = (_scrollPadding + index * _cardWidth).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _isCustomFood(String name) {
    for (final f in _allFoods) {
      if (f.name == name) return false;
    }
    return true;
  }

  void _addFood(int day, String order, Food food) {
    final slot = _meals[day]![order]!;
    setState(() {
      if (slot.staples.any((f) => f.id == food.id) ||
          slot.dishes.any((f) => f.id == food.id) ||
          slot.drinks.any((f) => f.id == food.id) ||
          slot.fruits.any((f) => f.id == food.id)) {
        slot.removeFood(food.id);
      }
      slot.addFood(food);
    });
  }

  void _removeFood(int day, String order, String id) {
    setState(() {
      _meals[day]![order]!.removeFood(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          tooltip: '返回选择日期',
          onPressed: widget.onBack,
        ),
        title: Text(
          '${_formatDay(widget.rangeStart)} ~ ${_formatDay(widget.rangeEnd)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF5EC),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildDinerCountRow(),
          const SizedBox(height: 8),
          _buildDaySelector(),
          const SizedBox(height: 12),
          Expanded(child: _buildMealScroll()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: FloatingActionButton(
          onPressed: () => _showSaveDialog(context),
          backgroundColor: const Color(0xFFFF8C42),
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<bool> _createMenu({
    required String name,
    required int dinerCount,
    required bool generateShopping,
  }) async {
    final daysData = <Map<String, dynamic>>[];
    final totalDays = widget.rangeEnd.difference(widget.rangeStart).inDays + 1;
    for (int d = 0; d < totalDays; d++) {
      final dayOfWeek = d + 1;
      final date = widget.rangeStart.add(Duration(days: d));
      final slot = _meals[dayOfWeek];
      if (slot == null) continue;

      // Build each meal section separately
      final fruitMeals = (slot['fruit']?.fruits ?? [])
          .map((f) => {'id': f.id, 'name': f.name, 'food_type': f.foodType}).toList();

      Map<String, List<Map<String, dynamic>>> mealSection(String orderKey) {
        final ms = slot[orderKey]!;
        return {
          'staple': ms.staples.map((f) => {'id': f.id, 'name': f.name, 'food_type': f.foodType}).toList(),
          'dish': ms.dishes.map((f) => {'id': f.id, 'name': f.name, 'food_type': f.foodType}).toList(),
          'drink': ms.drinks.map((f) => {'id': f.id, 'name': f.name, 'food_type': f.foodType}).toList(),
        };
      }

      daysData.add({
        'day_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'meals': {
          'fruit': fruitMeals,
          'breakfast': mealSection('breakfast'),
          'lunch': mealSection('lunch'),
          'dinner': mealSection('dinner'),
        },
      });
    }

    final result = await MenuService().create(
      name: name,
      dinerCount: dinerCount,
      startDate: '${widget.rangeStart.year}-${widget.rangeStart.month.toString().padLeft(2, '0')}-${widget.rangeStart.day.toString().padLeft(2, '0')}',
      endDate: '${widget.rangeEnd.year}-${widget.rangeEnd.month.toString().padLeft(2, '0')}-${widget.rangeEnd.day.toString().padLeft(2, '0')}',
      generateShopping: generateShopping,
      daysMeals: daysData,
    );
    return result != null;
  }

  void _showSaveDialog(BuildContext context) {
    final defaultName =
        '${_formatDay(widget.rangeStart)}-${_formatDay(widget.rangeEnd)} 食谱';
    final nameController = TextEditingController(text: defaultName);
    var generateShopping = true;
    var dialogDinerCount = _dinerCount;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('创建食谱'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '食谱名称',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('就餐人数'),
                      const Spacer(),
                      _buildCounterButton(
                        icon: Icons.remove,
                        onTap: dialogDinerCount > 1
                            ? () => setDialogState(() => dialogDinerCount--)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '$dialogDinerCount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(width: 14),
                      _buildCounterButton(
                        icon: Icons.add,
                        onTap: () =>
                            setDialogState(() => dialogDinerCount++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: generateShopping,
                        onChanged: (v) =>
                            setDialogState(() => generateShopping = v ?? true),
                        activeColor: const Color(0xFFFF8C42),
                      ),
                      const Text('一并生成采购清单'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    final ok = await _createMenu(
                      name: nameController.text,
                      dinerCount: dialogDinerCount,
                      generateShopping: generateShopping,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '「${nameController.text}」已创建${generateShopping ? "（含采购清单）" : ""}'
                            : '创建失败，请检查网络连接'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                  ),
                  child: const Text('确认创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---- diner count ----

  Widget _buildDinerCountRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.people_outline,
                color: Color(0xFFFF8C42), size: 18),
            const SizedBox(width: 8),
            const Text(
              '就餐人数',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D4037),
              ),
            ),
            const Spacer(),
            _buildCounterButton(
              icon: Icons.remove,
              onTap: _dinerCount > 1
                  ? () => setState(() => _dinerCount--)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              '$_dinerCount',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(width: 14),
            _buildCounterButton(
              icon: Icons.add,
              onTap: () => setState(() => _dinerCount++),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color:
              onTap != null ? const Color(0xFFFF8C42) : const Color(0xFFBDBDBD),
        ),
      ),
    );
  }

  // ---- day selector ----

  Widget _buildDaySelector() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _totalDays,
        itemBuilder: (context, index) {
          final date = widget.rangeStart.add(Duration(days: index));
          final isActive = index == _currentDay;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => _scrollToDay(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF8C42)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '周${_dayLabels[index % 7]}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isActive ? Colors.white : const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatDay(date),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- meal scroll ----

  Widget _buildMealScroll() {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemExtent: _cardWidth,
      itemCount: _totalDays,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final dayOfWeek = index + 1;
        final date = widget.rangeStart.add(Duration(days: index));
        return _buildDayCard(dayOfWeek, date);
      },
    );
  }

  Widget _buildDayCard(int day, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '周${_dayLabels[(day - 1) % 7]}  ${_formatDay(date)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF8C42),
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(_mealOrders.length, (m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildMealSection(day, m),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---- meal section (one breakfast/lunch/dinner) ----

  Widget _buildMealSection(int day, int mealIndex) {
    final order = _mealOrders[mealIndex];
    final slot = _meals[day]![order]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_mealIcons[mealIndex],
                size: 13, color: const Color(0xFF9E9E9E)),
            const SizedBox(width: 4),
            Text(
              _mealLabels[mealIndex],
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // chip area
        SizedBox(
          height: order == 'fruit' ? 32 : _foodDisplayHeight,
          child: _buildChipArea(slot, day, order),
        ),
        const SizedBox(height: 6),
        // input
        _MealInput(
          key: ValueKey('m${day}_$mealIndex'),
          onConfirm: (food) => _addFood(day, order, food),
          filterCategory: order == 'fruit' ? 'fruit' : null,
          mealOrder: order,
          foods: _allFoods,
          onDishAdded: (food) => setState(() => _allFoods = [..._allFoods, food]),
        ),
      ],
    );
  }

  List<Food> _sortedFoods(MealSlot slot) {
    final custom = <Food>[];
    final normal = <Food>[];

    for (final f in slot.dishes) {
      (_isCustomFood(f.name) ? custom : normal).add(f);
    }
    for (final f in slot.staples) {
      (_isCustomFood(f.name) ? custom : normal).add(f);
    }
    for (final f in slot.drinks) {
      (_isCustomFood(f.name) ? custom : normal).add(f);
    }
    for (final f in slot.fruits) {
      (_isCustomFood(f.name) ? custom : normal).add(f);
    }

    return [...custom, ...normal];
  }

  Color _chipColor(String category, String name) {
    if (_isCustomFood(name)) return const Color(0xFFE1BEE7);
    switch (category) {
      case 'dish':
        return const Color(0xFFFFE0B2);
      case 'staple':
        return const Color(0xFFFFF9C4);
      case 'drink':
        return const Color(0xFFBBDEFB);
      case 'fruit':
        return const Color(0xFFC8E6C9);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Widget _buildChipArea(MealSlot slot, int day, String order) {
    final foods = _sortedFoods(slot);
    if (foods.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final f in foods)
              _FoodChip(
                name: f.name,
                color: _chipColor(f.foodType, f.name),
                onDeleted: () => _removeFood(day, order, f.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodChip extends StatelessWidget {
  final String name;
  final Color color;
  final VoidCallback onDeleted;

  const _FoodChip({
    required this.name,
    required this.color,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(8, 0, 2, 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child:
                  Icon(Icons.close, size: 11, color: Color(0xFFFFAB91)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealInput extends StatefulWidget {
  final ValueChanged<Food> onConfirm;
  final String? filterCategory;
  final List<Food> foods;
  final String? mealOrder;
  final ValueChanged<Food>? onDishAdded;

  const _MealInput({
    super.key,
    required this.onConfirm,
    this.filterCategory,
    this.mealOrder,
    required this.foods,
    this.onDishAdded,
  });

  @override
  State<_MealInput> createState() => _MealInputState();
}

class _MealInputState extends State<_MealInput> {
  late TextEditingController _controller;
  bool _hasText = false;
  bool _isAdding = false;
  TextEditingController? _autoController;

  int _sortPriority(String foodType) {
    if (widget.mealOrder == 'breakfast') {
      switch (foodType) {
        case 'staple': return 0;
        case 'drink': return 1;
        case 'dish': return 2;
        case 'fruit': return 3;
        default: return 4;
      }
    }
    // lunch, dinner default: dish first
    switch (foodType) {
      case 'dish': return 0;
      case 'staple': return 1;
      case 'drink': return 2;
      case 'fruit': return 3;
      default: return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final text = _autoController?.text.trim() ?? _controller.text.trim();
    if (text.isEmpty) return;
    final existing = widget.foods.where((f) => f.name == text);
    if (existing.isNotEmpty) {
      _autoController?.clear();
      _controller.clear();
      widget.onConfirm(existing.first);
      return;
    }

    setState(() => _isAdding = true);
    try {
      final result = await DishService().addDish(text);
      if (!mounted) return;
      _autoController?.clear();
      _controller.clear();
      if (result != null) {
        final food = Food(id: result.id, name: result.name, foodType: result.foodType);
        widget.onDishAdded?.call(food);
        widget.onConfirm(food);
      } else {
        final fallback = Food(id: 'custom_${DateTime.now().millisecondsSinceEpoch}', name: text, foodType: 'dish');
        widget.onConfirm(fallback);
      }
    } catch (_) {
      if (!mounted) return;
      _autoController?.clear();
      _controller.clear();
      final fallback = Food(id: 'custom_${DateTime.now().millisecondsSinceEpoch}', name: text, foodType: 'dish');
      widget.onConfirm(fallback);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Autocomplete<Food>(
            optionsBuilder: (textEditingValue) {
              Iterable<Food> foods = widget.foods;
              if (widget.filterCategory != null) {
                foods = foods.where(
                    (f) => f.foodType == widget.filterCategory);
              }
              if (textEditingValue.text.isEmpty) {
                final sorted = foods.toList()
                  ..sort((a, b) => _sortPriority(a.foodType)
                      .compareTo(_sortPriority(b.foodType)));
                return sorted;
              }
              final sorted = foods
                  .where((f) => f.name.contains(textEditingValue.text))
                  .toList()
                ..sort((a, b) =>
                    _sortPriority(a.foodType)
                        .compareTo(_sortPriority(b.foodType)));
              return sorted;
            },
            displayStringForOption: (food) => food.name,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              _autoController = controller;
              return SizedBox(
                height: 36,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => _confirm(),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF5D4037)),
                  decoration: InputDecoration(
                    hintText: '选择食物',
                    hintStyle: const TextStyle(
                        fontSize: 11, color: Color(0xFFBDBDBD)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFFF8C42)),
                    ),
                  ),
                ),
              );
            },
            onSelected: (food) => _confirmViaSelect(food),
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  shadowColor: Colors.black26,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final food = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(food.name,
                              style: const TextStyle(fontSize: 12)),
                          trailing: Text(
                            food.foodType == 'staple'
                                ? '主食'
                                : food.foodType == 'drink'
                                    ? '饮品'
                                    : food.foodType == 'fruit'
                                        ? '水果'
                                        : '菜品',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF9E9E9E)),
                          ),
                          onTap: () => onSelected(food),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_hasText) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _isAdding ? null : _confirm,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _isAdding
                    ? const Color(0xFFFFCC80)
                    : const Color(0xFFFF8C42),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isAdding
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmViaSelect(Food food) {
    _autoController?.clear();
    _controller.clear();
    widget.onConfirm(food);
  }
}
