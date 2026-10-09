import 'dart:ui' as ui;

import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 把被测组件放进一个标准的 Material 环境里。
Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

/// 一个可计数的组件，用于验证 KeepAliveWrapper 是否保留了 State。
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Text('count: $count'),
          TextButton(
            key: const Key('inc'),
            onPressed: () => setState(() => count++),
            child: const Text('inc'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('AccurateSizedBox', () {
    testWidgets('SizedBox 的子组件会被父约束撑大，AccurateSizedBox 不会', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 100, height: 100),
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: ColoredBox(key: Key('sbChild'), color: Color(0xFFFF0000)),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 100, height: 100),
                child: const AccurateSizedBox(
                  width: 50,
                  height: 50,
                  child: ColoredBox(key: Key('asbChild'), color: Color(0xFF00FF00)),
                ),
              ),
            ],
          ),
        ),
      );

      // SizedBox 把父约束透传下去，子组件被撑到 100x100
      expect(tester.getSize(find.byKey(const Key('sbChild'))), const Size(100, 100));
      // AccurateSizedBox 强制子组件保持 50x50
      expect(tester.getSize(find.byKey(const Key('asbChild'))), const Size(50, 50));
    });

    testWidgets('布局尺寸仍遵守父约束（不会越界）', (tester) async {
      await tester.pumpWidget(
        _host(
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            child: const AccurateSizedBox(
              width: 200,
              height: 200,
              child: ColoredBox(key: Key('child'), color: Color(0xFF00FF00)),
            ),
          ),
        ),
      );
      // 想要 200x200，但父约束只有 40x40，子组件被限制为 40x40
      expect(tester.getSize(find.byKey(const Key('child'))), const Size(40, 40));
    });
  });

  group('AfterLayout', () {
    testWidgets('布局结束后回调，可拿到 size / offset / rect', (tester) async {
      RenderAfterLayout? captured;
      await tester.pumpWidget(
        _host(
          AfterLayout(
            callback: (ral) => captured = ral,
            child: const SizedBox(width: 120, height: 40),
          ),
        ),
      );
      await tester.pump(); // 触发 postFrameCallback

      expect(captured, isNotNull);
      expect(captured!.size, const Size(120, 40));
      expect(captured!.rect.width, 120);
      expect(captured!.rect.height, 40);
    });
  });

  group('LeftRightBox', () {
    testWidgets('右组件宽度不超过总宽度的一半，容器宽度铺满父约束', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: LeftRightBox(
              left: const Text('left'),
              right: const SizedBox(key: Key('right'), width: 500, height: 20),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('right'))).width, 150);
      expect(tester.getSize(find.byType(LeftRightBox)).width, 300);
    });
  });

  group('KeepAliveWrapper', () {
    testWidgets('列表项滑出屏幕后 State 不被销毁', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            children: [
              const KeepAliveWrapper(child: _Counter()),
              for (int i = 0; i < 30; i++) SizedBox(height: 100, child: Text('item$i')),
            ],
          ),
        ),
      );

      expect(find.text('count: 0'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inc')));
      await tester.pump();
      expect(find.text('count: 1'), findsOneWidget);

      // 滚到远处，第一项离开视口
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('count: 1'), findsNothing);

      // 滚回来，计数仍然是 1（说明 State 被保留而非重建）
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('count: 1'), findsOneWidget);
    });
  });

  group('DoneWidget', () {
    testWidgets('默认尺寸 25x25，300ms 动画从 0 走到 1', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Center(child: DoneWidget())));
      final RenderDoneObject render =
          tester.renderObject<RenderDoneObject>(find.byType(DoneWidget));

      expect(render.size, const Size(25, 25));
      expect(render.progress, 0.0);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900)); // 远超 300ms
      expect(render.progress, 1.0);
    });
  });

  group('TurnBox', () {
    testWidgets('turns 变化后动画到新角度', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: TurnBox(turns: 0, child: Icon(Icons.add)))),
      );
      expect(
        tester.widget<RotationTransition>(find.byType(RotationTransition)).turns.value,
        0.0,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Center(child: TurnBox(turns: 0.5, child: Icon(Icons.add)))),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<RotationTransition>(find.byType(RotationTransition)).turns.value,
        0.5,
      );
    });
  });

  group('GradientButton', () {
    testWidgets('可点击并回调；onPressed 为 null 时进入禁用态', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              GradientButton(onPressed: () => taps++, child: const Text('go')),
              const GradientButton(onPressed: null, child: Text('disabled')),
            ],
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      expect(taps, 1);

      await tester.tap(find.text('disabled'));
      await tester.pump();
      expect(taps, 1, reason: '禁用态不应该触发回调');
    });
  });

  group('GradientCircularProgressIndicator', () {
    testWidgets('按 radius 决定绘制尺寸', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: GradientCircularProgressIndicator(radius: 50, value: 0.5)),
        ),
      );
      expect(
        tester.getSize(find.byType(GradientCircularProgressIndicator)),
        const Size(100, 100),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ExtraInfoBoxConstraints', () {
    test('相同 extra 与约束相等且 hashCode 一致，extra 不同则不等', () {
      const BoxConstraints c = BoxConstraints.tightFor(width: 10, height: 20);
      final ExtraInfoBoxConstraints<String> a1 = ExtraInfoBoxConstraints<String>('a', c);
      final ExtraInfoBoxConstraints<String> a2 = ExtraInfoBoxConstraints<String>('a', c);
      final ExtraInfoBoxConstraints<String> b = ExtraInfoBoxConstraints<String>('b', c);

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1 == b, isFalse);
      expect(a1.asBoxConstraints(), equals(c));
    });
  });

  group('TextWaterMarkPainter', () {
    testWidgets('paintUnit 能离屏绘制并返回正数尺寸', (tester) async {
      for (final double rotate in <double>[0, -30, 30]) {
        final TextWaterMarkPainter painter =
            TextWaterMarkPainter(text: 'flukit', rotate: rotate);
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        final Size size = painter.paintUnit(canvas, 2.0);
        recorder.endRecording().dispose();

        expect(size.width, greaterThan(0), reason: 'rotate=$rotate');
        expect(size.height, greaterThan(0), reason: 'rotate=$rotate');
      }
    });
  });
}
