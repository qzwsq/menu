import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final Widget body;

  static const _titles = <String>[
    '新建食谱',
    '我的食谱',
    '采购清单',
  ];

  static const _icons = <IconData>[
    Icons.add_circle_outline,
    Icons.list_alt,
    Icons.shopping_cart_outlined,
  ];

  const AppScaffold({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(_titles[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(context),
                for (int i = 0; i < _titles.length; i++)
                  ListTile(
                    leading: Icon(_icons[i]),
                    title: Text(_titles[i]),
                    selected: selectedIndex == i,
                    onTap: () {
                      Navigator.of(context).pop();
                      onItemTapped(i);
                    },
                  ),
              ],
            ),
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemTapped,
            destinations: [
              for (int i = 0; i < _titles.length; i++)
                NavigationDestination(
                  icon: Icon(_icons[i]),
                  label: _titles[i],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: Colors.white),
          SizedBox(height: 8),
          Text(
            '菜单管理',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
