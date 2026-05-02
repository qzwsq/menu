import 'package:flutter/material.dart';

import '../models/menu.dart';
import '../services/menu_service.dart';
import 'shopping_list_page.dart';

class MenuDetailPage extends StatefulWidget {
  final int menuId;

  const MenuDetailPage({super.key, required this.menuId});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  MenuDetail? _detail;
  bool _loading = true;
  int _currentDay = 0;
  final ScrollController _scrollController = ScrollController();

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

  static const _chipColors = {
    'dish': Color(0xFFFFE0B2),
    'staple': Color(0xFFFFF9C4),
    'drink': Color(0xFFBBDEFB),
    'fruit': Color(0xFFC8E6C9),
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await MenuService().detail(widget.menuId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loading = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = (_scrollController.offset - _scrollPadding).clamp(0.0, double.infinity);
    final idx = (offset / _cardWidth).round();
    if (idx != _currentDay && _detail != null && idx >= 0 && idx < _detail!.meals.length) {
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

  String _formatDay(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${int.parse(parts[1])}.${int.parse(parts[2])}';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.name ?? '食谱详情'),
        backgroundColor: const Color(0xFFFFF5EC),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (_detail?.hasShoppingList == true)
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFFFF8C42)),
              tooltip: '查看采购清单',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ShoppingListPage(menuId: widget.menuId, menuName: _detail?.name),
                ));
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
          : _detail == null
              ? const Center(child: Text('加载失败'))
              : Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildDaySelector(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildMealScroll()),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final d = _detail!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, color: Color(0xFFFF8C42)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF5D4037))),
                const SizedBox(height: 4),
                Text('${d.dinerCount}人 · ${d.startDate} ~ ${d.endDate} · ${d.meals.length}天',
                    style: TextStyle(fontSize: 13, color: const Color(0xFF5D4037).withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    if (_detail == null) return const SizedBox.shrink();
    final days = _detail!.meals;
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentDay;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => _scrollToDay(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFF8C42) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '周${_dayLabels[index % 7]}',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatDay(days[index].dayDate),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF9E9E9E),
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

  Widget _buildMealScroll() {
    final days = _detail!.meals;
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemExtent: _cardWidth,
      itemCount: days.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        return _buildDayCard(days[index], index);
      },
    );
  }

  Widget _buildDayCard(MealItem meal, int dayIndex) {
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
                '周${_dayLabels[dayIndex % 7]}  ${_formatDay(meal.dayDate)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF8C42)),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < _mealOrders.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildMealSection(meal.mealsData, i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealSection(Map<String, dynamic> meals, int mealIndex) {
    final order = _mealOrders[mealIndex];
    final chips = _buildChips(meals, order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_mealIcons[mealIndex], size: 13, color: const Color(0xFF9E9E9E)),
            const SizedBox(width: 4),
            Text(_mealLabels[mealIndex],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: order == 'fruit' ? 32 : _foodDisplayHeight,
          child: chips.isEmpty
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: chips,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildChips(Map<String, dynamic> meals, String order) {
    final chips = <_FoodEntry>[];

    if (order == 'fruit') {
      final items = (meals['fruit'] as List<dynamic>?) ?? [];
      for (final item in items) {
        final name = item is Map ? item['name']?.toString() ?? '' : '$item';
        if (name.isNotEmpty) {
          chips.add(_FoodEntry(name: name, foodType: 'fruit'));
        }
      }
    } else {
      final section = meals[order] as Map<String, dynamic>? ?? {};
      for (final cat in ['staple', 'dish', 'drink']) {
        for (final item in (section[cat] as List<dynamic>?) ?? []) {
          final name = item is Map ? item['name']?.toString() ?? '' : '$item';
          if (name.isNotEmpty) {
            final ft = item is Map ? item['food_type']?.toString() : null;
            chips.add(_FoodEntry(name: name, foodType: ft ?? cat));
          }
        }
      }
    }

    // sort: dish → staple → drink → fruit (same as edit page)
    const sortOrder = {'dish': 0, 'staple': 1, 'drink': 2, 'fruit': 3};
    chips.sort((a, b) => (sortOrder[a.foodType] ?? 4).compareTo(sortOrder[b.foodType] ?? 4));

    return chips.map((e) => _ReadOnlyChip(
      name: e.name,
      color: _chipColors[e.foodType] ?? _chipColors['dish']!,
    )).toList();
  }
}

class _FoodEntry {
  final String name;
  final String foodType;
  const _FoodEntry({required this.name, required this.foodType});
}

class _ReadOnlyChip extends StatelessWidget {
  final String name;
  final Color color;

  const _ReadOnlyChip({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
        ],
      ),
    );
  }
}
