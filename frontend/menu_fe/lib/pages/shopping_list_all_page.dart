import 'package:flutter/material.dart';

import '../models/menu.dart';
import '../services/menu_service.dart';

import 'shopping_list_page.dart';

class ShoppingListAllPage extends StatefulWidget {
  const ShoppingListAllPage({super.key});

  @override
  State<ShoppingListAllPage> createState() => _ShoppingListAllPageState();
}

class _ShoppingListAllPageState extends State<ShoppingListAllPage> {
  List<ShoppingBrief> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await MenuService().listAllShopping();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('采购清单'),
        backgroundColor: const Color(0xFFFFF5EC),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
          : _items.isEmpty
              ? const Center(child: Text('暂无采购清单', style: TextStyle(color: Color(0xFF9E9E9E))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildCard(_items[index]),
                  ),
                ),
    );
  }

  Widget _buildCard(ShoppingBrief item) {
    final hasCategories = item.categories.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFFF8C42).withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShoppingListPage(menuId: item.menuId, menuName: '采购清单 - ${item.menuName}'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFFFF8C42)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('采购清单 - ${item.menuName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
                        const SizedBox(height: 2),
                        Text('${item.dinerCount}人 · ${item.weekStart}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
                ],
              ),
              if (hasCategories) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 8),
                for (final cat in item.categories)
                  _buildCategory(cat as Map<String, dynamic>),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(Map<String, dynamic> cat) {
    final name = cat['name'] as String? ?? '';
    final items = (cat['items'] as List<dynamic>?) ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C42),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
              const SizedBox(width: 6),
              Text('${items.length}项',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final item in items)
                _buildItemChip(item as Map<String, dynamic>),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemChip(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? '';
    final qty = item['total_quantity'] ?? '';
    final unit = item['unit'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        unit.isNotEmpty ? '$name $qty$unit' : name,
        style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
      ),
    );
  }
}
