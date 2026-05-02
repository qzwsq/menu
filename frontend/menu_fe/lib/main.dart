import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/menu_edit_page.dart';
import 'pages/menu_list_page.dart';
import 'pages/new_menu_page.dart';
import 'pages/shopping_list_all_page.dart';
import 'widgets/app_scaffold.dart';

void main() {
  initializeDateFormatting('zh_CN');
  runApp(const MenuApp());
}

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '菜单管理',
      locale: const Locale('zh'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8C42),
          brightness: Brightness.light,
        ),
        useMaterial3: defaultTargetPlatform != TargetPlatform.iOS,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pageStack = [];

  late final List<Widget> _basePages;

  @override
  void initState() {
    super.initState();
    _basePages = [
      NewMenuPage(onCreateMenu: _onCreateMenu),
      const MenuListPage(),
      const ShoppingListAllPage(),
    ];
    _pageStack.add(_basePages[0]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageStack.clear();
      _pageStack.add(_basePages[index]);
    });
  }

  void _onCreateMenu(DateTimeRange range) {
    setState(() {
      _pageStack.add(MenuEditPage(
        rangeStart: range.start,
        rangeEnd: range.end,
        onBack: _onMenuEditBack,
      ));
    });
  }

  void _onMenuEditBack() {
    setState(() => _pageStack.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pageStack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _pageStack.length > 1) {
          setState(() => _pageStack.removeLast());
        }
      },
      child: AppScaffold(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        body: _pageStack.last,
      ),
    );
  }
}
