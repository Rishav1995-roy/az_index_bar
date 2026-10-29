// Proofs for the core problems that define the gap left by `azlistview`
// (see CLAUDE.md "Core problems"). Test names start with the problem id.
import 'dart:io';

import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

Widget list(
  AzGroups<String> g, {
  double? itemExtent,
  AzSectionedListController? controller,
  AzDisabledBehavior behavior = AzDisabledBehavior.snapToNext,
  double height = 600,
}) =>
    host(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: height,
          child: AzSectionedListView<String>(
            groups: g,
            controller: controller,
            itemExtent: itemExtent,
            headerExtent: 30,
            hapticFeedback: false,
            disabledBehavior: behavior,
            // variable heights unless itemExtent is given
            itemBuilder: (BuildContext c, String item, int s, int i) =>
                SizedBox(
              height: itemExtent ?? 40.0 + (i % 4) * 14,
              child: Text(item),
            ),
            headerBuilder: (BuildContext c, AzSection<String> s, int i) =>
                ColoredBox(color: Colors.grey, child: Text('hdr ${s.label}')),
          ),
        ),
      ),
    );

double headerTop(WidgetTester t, String label) =>
    t.getTopLeft(find.text('hdr $label')).dy;

void main() {
  final AzGroups<String> groups =
      AzGroups<String>.from(syntheticNames(), textOf: (String s) => s);

  test(
      'CORE-1a (azlistview#75, #92): no dependency on scrollable_positioned_list',
      () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String deps = pubspec.split('dev_dependencies:').first;
    expect(deps, isNot(contains('scrollable_positioned_list')));
    expect(deps, isNot(contains('azlistview')));
    // Only flutter itself.
    final Iterable<RegExpMatch> pkgs = RegExp(r'^  ([a-z_]+):', multiLine: true)
        .allMatches(deps.split('dependencies:').last);
    expect(
        pkgs.map((RegExpMatch m) => m.group(1)).toList(), <String?>['flutter']);
  });

  for (final double? extent in <double?>[null, 48]) {
    final String mode =
        extent == null ? 'variable-height items' : 'fixed-height items';

    testWidgets(
        'CORE-1b (azlistview#75): a plain ScrollController jumps to the tapped section, $mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(list(groups, itemExtent: extent));
      for (final String label in <String>['M', 'T', 'F', 'B']) {
        await tester.tap(barText(label));
        await tester.pumpAndSettle();
        expect(headerTop(tester, label), closeTo(0, 1),
            reason: 'header $label must sit at the top after jumping');
      }
    });

    testWidgets('CORE-1c: dragging the bar scrubs through sections, $mode',
        (WidgetTester tester) async {
      final AzSectionedListController c = AzSectionedListController();
      addTearDown(c.dispose);
      await tester.pumpWidget(list(groups, itemExtent: extent, controller: c));
      final TestGesture g =
          await tester.startGesture(tester.getCenter(barText('A')));
      for (final String l in <String>['B', 'C', 'D', 'E', 'F', 'G', 'H']) {
        await g.moveTo(tester.getCenter(barText(l)));
        await tester.pump();
        expect(headerTop(tester, l), closeTo(0, 1));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(groups.sections[c.currentSection.value].label, 'H');
    });
  }

  testWidgets(
      'CORE-1d: the bar highlights the section at the top while scrolling',
      (WidgetTester tester) async {
    final AzSectionedListController c = AzSectionedListController();
    addTearDown(c.dispose);
    await tester.pumpWidget(list(groups, controller: c));
    c.scrollController.jumpTo(0);
    await tester.pump();
    expect(c.currentSection.value, 0);
    await tester.tap(barText('R'));
    await tester.pumpAndSettle();
    // user flicks a little: still R or the next one, never a far-away section
    final int r = groups.sectionIndexOfLabel('R');
    expect(c.currentSection.value, r);
    c.scrollController.jumpTo(c.scrollController.offset + 5000);
    await tester.pumpAndSettle();
    expect(c.currentSection.value, greaterThan(r));
  });

  group('CORE-2 (azlistview#101): the bubble must always disappear', () {
    testWidgets('after release', (WidgetTester tester) async {
      await tester.pumpWidget(
          barHost(labels: alphabet, onSelected: (int i, String l) {}));
      final TestGesture g =
          await tester.startGesture(tester.getCenter(barText('A')));
      await g.moveTo(tester.getCenter(barText('Q')));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsOneWidget);
      await g.up();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsNothing);
    });

    testWidgets('after the pointer is cancelled (e.g. system gesture)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          barHost(labels: alphabet, onSelected: (int i, String l) {}));
      final TestGesture g =
          await tester.startGesture(tester.getCenter(barText('C')));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsOneWidget);
      await g.cancel();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsNothing);
    });

    testWidgets('after very fast taps and drags repeated many times',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          barHost(labels: alphabet, onSelected: (int i, String l) {}));
      for (int i = 0; i < 20; i++) {
        final TestGesture g =
            await tester.startGesture(tester.getCenter(barText('B')));
        if (i.isEven) await g.moveTo(tester.getCenter(barText('Y')));
        if (i % 3 == 0) {
          await g.cancel();
        } else {
          await g.up();
        }
      }
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsNothing);
    });

    testWidgets('a second finger does not leave the bubble stuck',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          barHost(labels: alphabet, onSelected: (int i, String l) {}));
      final TestGesture a =
          await tester.startGesture(tester.getCenter(barText('C')), pointer: 1);
      final TestGesture b =
          await tester.startGesture(tester.getCenter(barText('M')), pointer: 2);
      await b.up(); // ignored pointer, bubble still driven by the first
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsOneWidget);
      await a.up();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('az_bubble')), findsNothing);
    });
  });

  group(
      'CORE-3 (azlistview#104, #95): haptics are a tick per label, with a hook',
      () {
    testWidgets(
        'exactly one tick per label crossed, none while staying on a label',
        (WidgetTester tester) async {
      int ticks = 0;
      await tester.pumpWidget(barHost(
        labels: alphabet,
        onSelected: (int i, String l) {},
        onHaptic: () => ticks++,
      ));
      final TestGesture g =
          await tester.startGesture(tester.getCenter(barText('A')));
      for (final String l in <String>['B', 'C', 'D']) {
        await g.moveTo(tester.getCenter(barText(l)));
        for (int k = 0; k < 4; k++) {
          await g.moveBy(const Offset(0, 0.4));
        }
      }
      await g.up();
      expect(ticks, 4); // A, B, C, D
    });
  });

  group(
      'CORE-4 (azlistview#100, #73, #88): short lists, tall labels, small screens',
      () {
    testWidgets(
        '#100: a list shorter than the viewport still selects every section',
        (WidgetTester tester) async {
      final AzGroups<String> tiny = AzGroups<String>.from(
        <String>['Ann', 'Amy', 'Bob', 'Bea', 'Cy'],
        textOf: (String s) => s,
      );
      final AzSectionedListController c = AzSectionedListController();
      addTearDown(c.dispose);
      await tester.pumpWidget(list(tiny, itemExtent: 48, controller: c));
      await tester.tap(barText('C'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(c.currentSection.value, 2);
      expect(headerTop(tester, 'C'), greaterThanOrEqualTo(0));
      await tester.tap(barText('B'));
      await tester.pumpAndSettle();
      expect(c.currentSection.value, 1);
      expect(find.text('hdr B'), findsOneWidget);
    });

    testWidgets('#100: a list with one or two items does not break',
        (WidgetTester tester) async {
      final AzSectionedListController c = AzSectionedListController();
      addTearDown(c.dispose);
      await tester.pumpWidget(list(
        AzGroups<String>.from(<String>['Zed'], textOf: (String s) => s),
        controller: c,
      ));
      await tester.tap(barText('Z'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Zed'), findsOneWidget);
    });

    testWidgets('#73: tall labels are each hittable',
        (WidgetTester tester) async {
      final List<String> labels = <String>['A', 'B', 'C', 'D', 'E', 'F'];
      final List<String> picked = <String>[];
      await tester.pumpWidget(barHost(
        labels: labels,
        onSelected: (int i, String l) => picked.add(l),
        haptics: false,
        theme: const AzIndexBarThemeData(maxLabelExtent: 90),
      ));
      for (final String l in labels) {
        await tester.tap(barText(l));
      }
      expect(picked, labels);
    });

    testWidgets('#88: a short screen collapses into dots without overflow',
        (WidgetTester tester) async {
      final List<String> picked = <String>[];
      await tester.pumpWidget(barHost(
        labels: alphabet,
        onSelected: (int i, String l) => picked.add(l),
        haptics: false,
        height: 150,
      ));
      expect(tester.takeException(), isNull);
      final int shown =
          alphabet.where((String l) => barText(l).evaluate().isNotEmpty).length;
      expect(shown, lessThan(alphabet.length));
      expect(shown, greaterThanOrEqualTo(2));
      expect(barText('A'), findsOneWidget);
      expect(barText('#'), findsOneWidget);
      // The whole bar fits the height it was given.
      expect(tester.getSize(find.byType(AzIndexBar)).height, 150);

      // Touching the very top and bottom still reaches the first / last label;
      // dragging the whole bar visits labels in increasing order.
      final Rect r = tester.getRect(find.byType(AzIndexBar));
      final TestGesture g =
          await tester.startGesture(Offset(r.center.dx, r.top + 1));
      for (double y = r.top + 2; y < r.bottom; y += 3) {
        await g.moveTo(Offset(r.center.dx, y));
      }
      await g.up();
      expect(picked.first, 'A');
      expect(picked.last, '#');
      final List<int> idx = picked.map(alphabet.indexOf).toList();
      expect(idx, orderedEquals(<int>[...idx]..sort()));
    });

    testWidgets('#88: the same bar re-lays out when the screen height changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(barHost(
          labels: alphabet, onSelected: (int i, String l) {}, height: 600));
      expect(barText('M'), findsOneWidget);
      await tester.pumpWidget(barHost(
          labels: alphabet, onSelected: (int i, String l) {}, height: 140));
      expect(barText('M'), findsNothing); // collapsed
      await tester.pumpWidget(barHost(
          labels: alphabet, onSelected: (int i, String l) {}, height: 600));
      expect(barText('M'), findsOneWidget);
    });
  });

  group('CORE-5: locale-aware grouping end to end', () {
    testWidgets(
        'German names with umlauts are grouped under the base letter and the bar greys empty letters',
        (WidgetTester tester) async {
      final AzGroups<String> de = AzGroups<String>.from(
        <String>[
          'Ärztin Mia',
          'Anja',
          'Özil Tom',
          'Olga',
          'Ümit',
          'Uwe',
          '1. Hilfe'
        ],
        textOf: (String s) => s,
      );
      expect(de.sections.map((AzSection<String> s) => s.label),
          <String>['A', 'O', 'U', '#']);
      expect(de.sections[0].items, <String>['Anja', 'Ärztin Mia']);
      final AzSectionedListController c = AzSectionedListController();
      addTearDown(c.dispose);
      await tester.pumpWidget(list(de, itemExtent: 48, controller: c));
      await tester.tap(barText('C')); // empty letter -> snaps to next (O)
      await tester.pumpAndSettle();
      expect(de.sections[c.currentSection.value].label, 'O');
    });
  });
}
