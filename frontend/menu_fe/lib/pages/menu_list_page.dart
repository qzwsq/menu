import 'package:flutter/material.dart';

import '../models/menu.dart';
import '../services/menu_service.dart';
import 'menu_detail_page.dart';

class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  List<MenuBrief> _menus = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final menus = await MenuService().list();
    if (!mounted) return;
    setState(() {
      _menus = menus;
      _loading = false;
    });
  }

  Future<void> _deleteMenu(MenuBrief menu) async {
    final deleteShopping = menu.hasShoppingList
        ? await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除食谱'),
              content: const Text('是否同时删除关联的采购清单？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('保留')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF8C42)),
                  child: const Text('一并删除'),
                ),
              ],
            ),
          )
        : false;

    final ok = await MenuService().delete(menu.id, deleteShopping: deleteShopping ?? false);
    if (ok && mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的食谱'),
        backgroundColor: const Color(0xFFFFF5EC),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
          : _menus.isEmpty
              ? const Center(child: Text('暂无食谱', style: TextStyle(color: Color(0xFF9E9E9E))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menus.length,
                    itemBuilder: (context, index) {
                      final m = _menus[index];
                      return _buildCard(m);
                    },
                  ),
                ),
    );
  }

  Widget _buildCard(MenuBrief menu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFFF8C42).withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MenuDetailPage(menuId: menu.id)),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_menu, color: Color(0xFFFF8C42)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
                    const SizedBox(height: 4),
                    Text('${menu.dinerCount}人 · ${menu.startDate} ~ ${menu.endDate}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              if (menu.hasShoppingList)
                const Icon(Icons.shopping_cart_outlined, size: 20, color: Color(0xFFFF8C42)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFFFAB91)),
                onPressed: () => _deleteMenu(menu),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
