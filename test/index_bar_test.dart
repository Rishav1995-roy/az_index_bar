import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  testWidgets('tap selects a label and shows then hides the bubble',
      (WidgetTester tester) async {
    final List<String> picked = <String>[];
    await tester.pumpWidget(barHost(
      labels: alphabet,
      onSelected: (int i, String l) => picked.add(l),
      haptics: false,
    ));
    final TestGesture g =
        await tester.startGesture(tester.getCenter(barText('K')));
    await tester.pump();
    expect(picked, <String>['K']);
    expect(find.byKey(const ValueKey<String>('az_bubble')), findsOneWidget);
    await g.up();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('az_bubble')), findsNothing);
  });

  testWidgets('dragging reports each new label once, in order',
      (WidgetTester tester) async {
    final List<String> picked = <String>[];
    await tester.pumpWidget(barHost(
      labels: alphabet,
      onSelected: (int i, String l) => picked.add(l),
      haptics: false,
    ));
    final TestGesture g =
        await tester.startGesture(tester.getCenter(barText('A')));
    for (final String l in <String>['B', 'C', 'D', 'E', 'F']) {
      await g.moveTo(tester.getCenter(barText(l)));
      await g.moveBy(const Offset(0, 1)); // same label: no new callback
    }
    await g.up();
    expect(picked, <String>['A', 'B', 'C', 'D', 'E', 'F']);
  });

  testWidgets('touching beyond the first/last label clamps to them',
      (WidgetTester tester) async {
    final List<String> picked = <String>[];
    await tester.pumpWidget(barHost(
      labels: alphabet,
      onSelected: (int i, String l) => picked.add(l),
      haptics: false,
    ));
    final Rect bar = tester.getRect(find.byType(AzIndexBar));
    final TestGesture g =
        await tester.startGesture(Offset(bar.center.dx, bar.top + 0.5));
    await g.moveTo(Offset(bar.center.dx, bar.bottom - 0.5));
    await g.up();
    expect(picked.first, 'A');
    expect(picked.last, '#');
  });

  group('disabled labels', () {
    final Set<String> enabled = <String>{'A', 'D', 'H'};

    Future<List<String>> tapBehavior(
      WidgetTester tester,
      AzDisabledBehavior b,
      String label,
    ) async {
      final List<String> picked = <String>[];
      await tester.pumpWidget(barHost(
        labels: alphabet,
        enabled: enabled,
        onSelected: (int i, String l) => picked.add(l),
        haptics: false,
        behavior: b,
      ));
      await tester.tap(barText(label));
      await tester.pump();
      return picked;
    }

    testWidgets('snapToNext picks the following enabled label',
        (WidgetTester tester) async {
      expect(await tapBehavior(tester, AzDisabledBehavior.snapToNext, 'B'),
          <String>['D']);
    });

    testWidgets('snapToNext falls back to the previous one at the end',
        (WidgetTester tester) async {
      expect(await tapBehavior(tester, AzDisabledBehavior.snapToNext, 'Z'),
          <String>['H']);
    });

    testWidgets('snapToNearest picks the closest', (WidgetTester tester) async {
      expect(await tapBehavior(tester, AzDisabledBehavior.snapToNearest, 'C'),
          <String>['D']);
      expect(await tapBehavior(tester, AzDisabledBehavior.snapToNearest, 'F'),
          <String>['H']); // tie goes to next
      expect(await tapBehavior(tester, AzDisabledBehavior.snapToNearest, 'G'),
          <String>['H']);
      expect(await tapBehavior(tester, AzDisabledBehavior.snapToNearest, 'Z'),
          <String>['H']);
    });

    testWidgets('ignore does nothing', (WidgetTester tester) async {
      expect(
          await tapBehavior(tester, AzDisabledBehavior.ignore, 'B'), isEmpty);
    });

    testWidgets('disabled labels use the disabled style',
        (WidgetTester tester) async {
      const Color dis = Color(0xFFAA0000);
      await tester.pumpWidget(barHost(
        labels: alphabet,
        enabled: enabled,
        onSelected: (int i, String l) {},
        theme: const AzIndexBarThemeData(
          disabledLabelStyle: TextStyle(color: dis),
          labelStyle: TextStyle(color: Color(0xFF00AA00)),
        ),
      ));
      expect(tester.widget<Text>(barText('B')).style!.color, dis);
      expect(tester.widget<Text>(barText('D')).style!.color,
          const Color(0xFF00AA00));
    });
  });

  group('haptics', () {
    testWidgets('onHaptic fires once per label change, not per move event',
        (WidgetTester tester) async {
      int haptics = 0;
      await tester.pumpWidget(barHost(
        labels: alphabet,
        onSelected: (int i, String l) {},
        onHaptic: () => haptics++,
      ));
      final Offset a = tester.getCenter(barText('A'));
      final TestGesture g = await tester.startGesture(a);
      expect(haptics, 1);
      for (int i = 0; i < 5; i++) {
        await g.moveBy(const Offset(0, 0.5)); // stays inside A
      }
      expect(haptics, 1);
      await g.moveTo(tester.getCenter(barText('B')));
      expect(haptics, 2);
      await g.up();
    });

    testWidgets('default feedback uses the platform haptic channel',
        (WidgetTester tester) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall c) async {
          calls.add(c);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(
          barHost(labels: alphabet, onSelected: (int i, String l) {}));
      await tester.tap(barText('C'));
      expect(
        calls
            .where((MethodCall c) => c.method == 'HapticFeedback.vibrate')
            .length,
        1,
      );
    });

    testWidgets('hapticFeedback: false is silent', (WidgetTester tester) async {
      int haptics = 0;
      await tester.pumpWidget(barHost(
        labels: alphabet,
        onSelected: (int i, String l) {},
        onHaptic: () => haptics++,
        haptics: false,
      ));
      await tester.tap(barText('C'));
      expect(haptics, 0);
    });
  });

  testWidgets('onSelectionStart/End are paired, also on dispose while touching',
      (WidgetTester tester) async {
    int starts = 0, ends = 0;
    await tester.pumpWidget(barHost(
      labels: alphabet,
      onSelected: (int i, String l) {},
      haptics: false,
      onStart: () => starts++,
      onEnd: () => ends++,
    ));
    final TestGesture g =
        await tester.startGesture(tester.getCenter(barText('C')));
    expect((starts, ends), (1, 0));
    await tester.pumpWidget(const SizedBox()); // bar removed mid-touch
    expect((starts, ends), (1, 1));
    await g.up();
  });

  group('highlight', () {
    testWidgets('currentLabel is highlighted when idle',
        (WidgetTester tester) async {
      const Color active = Color(0xFFFF0000);
      await tester.pumpWidget(barHost(
        labels: alphabet,
        current: 'C',
        onSelected: (int i, String l) {},
        theme: const AzIndexBarThemeData(activeBackgroundColor: active),
      ));
      await tester.pumpAndSettle();
      final Iterable<Container> red = tester
          .widgetList<Container>(find.descendant(
              of: find.byType(AzIndexBar), matching: find.byType(Container)))
          .where((Container c) =>
              c.decoration is ShapeDecoration &&
              (c.decoration! as ShapeDecoration).color == active);
      expect(red.length, 1);
      expect(
        tester.getCenter(find.byWidget(red.single)).dy,
        closeTo(tester.getCenter(barText('C')).dy, 0.5),
      );
    });
  });

  group('bubble', () {
    testWidgets('sits on the inner side of the bar in LTR and RTL',
        (WidgetTester tester) async {
      for (final TextDirection d in TextDirection.values) {
        await tester.pumpWidget(barHost(
          labels: alphabet,
          onSelected: (int i, String l) {},
          haptics: false,
          direction: d,
        ));
        final double barX = tester.getCenter(find.byType(AzIndexBar)).dx;
        final TestGesture g =
            await tester.startGesture(tester.getCenter(barText('M')));
        await tester.pump();
        final double bubbleX = tester
            .getCenter(find.byKey(const ValueKey<String>('az_bubble')))
            .dx;
        if (d == TextDirection.ltr) {
          expect(barX > 400, isTrue); // bar at the right edge
          expect(bubbleX < barX, isTrue);
        } else {
          expect(barX < 400, isTrue); // bar at the left edge
          expect(bubbleX > barX, isTrue);
        }
        await g.up();
      }
    });

    testWidgets('bubbleBuilder and showBubble', (WidgetTester tester) async {
      await tester.pumpWidget(host(Stack(children: <Widget>[
        PositionedDirectional(
          end: 0,
          top: 0,
          height: 600,
          child: AzIndexBar(
            labels: alphabet,
            onIndexSelected: (int i, String l) {},
            hapticFeedback: false,
            bubbleBuilder: (BuildContext c, String l) => Text('custom-$l'),
          ),
        ),
      ])));
      final TestGesture g =
          await tester.startGesture(tester.getCenter(barText('M')));
      await tester.pump();
      expect(find.text('custom-M'), findsOneWidget);
      await g.up();

      await tester.pumpWidget(host(Stack(children: <Widget>[
        PositionedDirectional(
          end: 0,
          top: 0,
          height: 600,
          child: AzIndexBar(
            labels: alphabet,
            onIndexSelected: (int i, String l) {},
            hapticFeedback: false,
            showBubble: false,
          ),
        ),
      ])));
      final TestGesture g2 =
          await tester.startGesture(tester.getCenter(barText('M')));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsNothing);
      await g2.up();
    });
  });

  group('accessibility', () {
    testWidgets('exposes a slider-like node that steps over enabled labels',
        (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      final List<String> picked = <String>[];
      await tester.pumpWidget(barHost(
        labels: alphabet,
        enabled: <String>{'A', 'D', 'H'},
        current: 'D',
        onSelected: (int i, String l) => picked.add(l),
        haptics: false,
      ));
      final Finder node = find.bySemanticsLabel('Section index');
      expect(node, findsOneWidget);
      final SemanticsNode n = tester.getSemantics(node);
      expect(n.value, 'D');
      expect(n.increasedValue, 'H');
      expect(n.decreasedValue, 'A');
      final FinderBase<SemanticsNode> bar =
          find.semantics.byLabel('Section index');
      tester.semantics.increase(bar);
      tester.semantics.decrease(bar);
      expect(picked, <String>['H', 'A']);
      h.dispose();
    });
  });

  group('theming', () {
    test('copyWith, merge, equality', () {
      const AzIndexBarThemeData a =
          AzIndexBarThemeData(width: 30, bubbleSize: 40);
      final AzIndexBarThemeData b = a.copyWith(width: 20, dotSize: 6);
      expect(b.width, 20);
      expect(b.bubbleSize, 40);
      expect(a.merge(b).dotSize, 6);
      expect(a.merge(null), a);
      expect(a == a.copyWith(), isTrue);
      expect(a.hashCode, a.copyWith().hashCode);
      expect(a == b, isFalse);
    });

    testWidgets('AzIndexBarTheme scope is picked up; widget theme wins',
        (WidgetTester tester) async {
      await tester.pumpWidget(AzIndexBarTheme(
        data: const AzIndexBarThemeData(width: 44, bubbleSize: 70),
        child: barHost(
          labels: alphabet,
          onSelected: (int i, String l) {},
          haptics: false,
          theme: const AzIndexBarThemeData(bubbleSize: 90),
        ),
      ));
      // AzIndexBarTheme above MaterialApp: still reachable.
      expect(tester.getSize(find.byType(AzIndexBar)).width, 44);
      final TestGesture g =
          await tester.startGesture(tester.getCenter(barText('M')));
      await tester.pump();
      expect(
          tester.getSize(find.byKey(const ValueKey<String>('az_bubble'))).width,
          90);
      await g.up();
    });
  });
}
