import 'package:flukit/example/common/page_scaffold.dart';
import 'package:flukitdemo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('首页渲染出组件列表', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Flukit demo'), findsOneWidget);
    expect(find.text('AfterLayout'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('点击列表项可以进入示例页', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('DoneWidget'));
    await tester.pumpAndSettle();

    final PageScaffold page = tester.widget<PageScaffold>(find.byType(PageScaffold));
    expect(page.title, 'DoneWidget');
  });

  testWidgets('可以滚动到列表末尾并进入 WaterMark 示例页', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('WaterMark(水印)'), 300);
    await tester.tap(find.text('WaterMark(水印)'));
    await tester.pumpAndSettle();

    final PageScaffold page = tester.widget<PageScaffold>(find.byType(PageScaffold));
    expect(page.title, 'WaterMark(水印)');
  });

  testWidgets('返回后回到列表页', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('LeftRightBox'));
    await tester.pumpAndSettle();
    expect(tester.widget<PageScaffold>(find.byType(PageScaffold)).title, 'LeftRightBox');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PageScaffold), findsNothing);
    expect(find.text('Flukit demo'), findsOneWidget);
  });
}
