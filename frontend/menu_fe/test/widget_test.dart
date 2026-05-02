import 'package:flutter_test/flutter_test.dart';

import 'package:menu_fe/main.dart';

void main() {
  testWidgets('App renders with drawer', (WidgetTester tester) async {
    await tester.pumpWidget(const MenuApp());
    expect(find.text('新建食谱'), findsOneWidget);
  });
}
