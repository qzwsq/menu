import 'package:flutter/material.dart';

import '../models/menu.dart';
import '../services/menu_service.dart';

class ShoppingListPage extends StatefulWidget {
  final int menuId;
  final String? menuName;

  const ShoppingListPage({super.key, required this.menuId, this.menuName});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  ShoppingListData? _data;
  bool _loading = true;
  final _checked = <String>{};
  final _collapsed = <String>{};
  final _hidden = <String>{};

  static const _bodyStyle = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: Color(0xFF4E342E),
  );

  static const _metaStyle = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: Color(0xFFA1887F),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await MenuService().getShoppingList(widget.menuId);
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  bool _isVisible(String catName, String itemName) =>
      !_hidden.contains('$catName::$itemName');

  bool _isChecked(String catName, String itemName) =>
      _checked.contains('$catName::$itemName');

  int _visibleCount(String catName, List<dynamic> items) =>
      items.where((item) => _isVisible(catName, (item as Map<String, dynamic>)['name'] as String? ?? '')).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuName ?? '采购清单'),
        backgroundColor: const Color(0xFFFFF5EC),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
          : _data == null
              ? const Center(child: Text('暂无采购清单'))
              : _data!.categories.isEmpty
                  ? const Center(child: Text('暂无食材数据', style: TextStyle(color: Color(0xFF9E9E9E))))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 12),
                        ..._buildCategories(),
                      ],
                    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Color(0xFFFF8C42), size: 22),
          const SizedBox(width: 10),
          Text(
            '${_data!.dinerCount}人份 · ${_data!.weekStart}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategories() {
    final cats = _data!.categories;
    final widgets = <Widget>[];

    for (var ci = 0; ci < cats.length; ci++) {
      final cat = cats[ci] as Map<String, dynamic>;
      final catName = cat['name'] as String? ?? '';
      final items = (cat['items'] as List<dynamic>?) ?? [];
      final collapsed = _collapsed.contains(catName);
      final visibleCount = _visibleCount(catName, items);

      if (visibleCount == 0) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      final visibleItems = items.where((item) {
        final name = (item as Map<String, dynamic>)['name'] as String? ?? '';
        return _isVisible(catName, name);
      }).toList();

      final allVisibleChecked = visibleItems.every(
        (item) => _isChecked(catName, (item as Map<String, dynamic>)['name'] as String? ?? ''),
      );

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildCategoryHeader(
                catName,
                visibleCount,
                allVisibleChecked,
                collapsed,
                visibleItems,
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    for (final item in visibleItems)
                      _buildItemRow(catName, item as Map<String, dynamic>,
                          visibleItems.length),
                  ],
                ),
                crossFadeState: collapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCategoryHeader(
    String catName,
    int visibleCount,
    bool allChecked,
    bool collapsed,
    List<dynamic> visibleItems,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          if (collapsed) {
            _collapsed.remove(catName);
          } else {
            _collapsed.add(catName);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: allChecked && visibleItems.isNotEmpty,
                activeColor: const Color(0xFFFF8C42),
                visualDensity: VisualDensity.compact,
                tristate: false,
                onChanged: (_) {
                  setState(() {
                    if (allChecked) {
                      for (final item in visibleItems) {
                        final name = (item as Map<String, dynamic>)['name'] as String? ?? '';
                        _checked.remove('$catName::$name');
                      }
                    } else {
                      for (final item in visibleItems) {
                        final name = (item as Map<String, dynamic>)['name'] as String? ?? '';
                        _checked.add('$catName::$name');
                      }
                    }
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                catName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: allChecked ? const Color(0xFFBCAAA4) : const Color(0xFF4E342E),
                ),
              ),
            ),
            Text(
              '$visibleCount',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFA1887F),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: collapsed ? 0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFFA1887F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(String catName, Map<String, dynamic> i, int siblingCount) {
    final itemName = i['name'] as String? ?? '';
    final qty = i['purchase_quantity'] ?? i['total_quantity'] ?? '';
    final qtyDisplay = (qty is num && qty.toDouble() == qty.toDouble().truncateToDouble())
        ? qty.toInt().toString()
        : qty.toString();
    final unit = i['purchase_unit'] as String? ?? i['unit'] as String? ?? '';
    final sources = (i['source_foods'] as List<dynamic>?) ?? [];
    final checked = _isChecked(catName, itemName);

    return Dismissible(
      key: ValueKey('$catName::$itemName'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFFAB91),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _hidden.add('$catName::$itemName'));
      },
      child: InkWell(
        onTap: () {
          setState(() {
            final key = '$catName::$itemName';
            if (checked) {
              _checked.remove(key);
            } else {
              _checked.add(key);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: checked,
                  activeColor: const Color(0xFFFF8C42),
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) {},
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: checked
                          ? _bodyStyle.copyWith(
                              color: const Color(0xFFA1887F),
                              decoration: TextDecoration.lineThrough,
                            )
                          : _bodyStyle,
                    ),
                    if (qtyDisplay != '0' && unit.isNotEmpty || sources.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (qtyDisplay != '0' && unit.isNotEmpty) '$qtyDisplay$unit',
                          if (sources.isNotEmpty) '(${sources.join('、')})',
                        ].join(' '),
                        style: _metaStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
