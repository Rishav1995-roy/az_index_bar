import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('metrics', () {
    test('fixed metrics: offsets and lookup', () {
      final AzFixedSectionMetrics m = AzFixedSectionMetrics(
        itemCounts: <int>[2, 3, 1],
        headerExtent: 10,
        itemExtent: 50,
        leadingExtent: 5,
      );
      expect(m.sectionCount, 3);
      expect(m.offsetOfSection(0), 5);
      expect(m.offsetOfSection(1), 5 + 110);
      expect(m.offsetOfSection(2), 5 + 110 + 160);
      expect(m.sectionAtOffset(0), 0);
      expect(m.sectionAtOffset(114), 0);
      expect(m.sectionAtOffset(115), 1);
      expect(m.sectionAtOffset(5000), 2);
      expect(m.isExact, isTrue);
    });

    test('extent metrics with variable section heights', () {
      final AzExtentSectionMetrics m =
          AzExtentSectionMetrics(<double>[100, 30, 400]);
      expect(m.offsetOfSection(2), 130);
      expect(m.sectionAtOffset(129), 1);
      expect(AzExtentSectionMetrics(<double>[]).sectionAtOffset(10), 0);
    });
  });

  group('AzSectionScroller on a plain ScrollController', () {
    testWidgets('jumps, animates, reports current section and locks the last',
        (WidgetTester tester) async {
      final ScrollController c = ScrollController();
      addTearDown(c.dispose);
      // 5 sections x 200 px, viewport 500 -> max scroll 500.
      final AzSectionScroller s = AzSectionScroller(
        controller: c,
        metrics: AzExtentSectionMetrics(List<double>.filled(5, 200)),
      );
      addTearDown(s.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 500,
            child: ListView(
              controller: c,
              children: List<Widget>.generate(
                5,
                (int i) => SizedBox(height: 200, child: Text('s$i')),
              ),
            ),
          ),
        ),
      ));
      s.jumpToSection(1);
      expect(c.offset, 200);
      expect(s.currentSection.value, 1);

      // Section 4 starts at 800 but the list can only scroll to 500:
      // section 4 must still be reported (the "last sections unreachable" bug).
      s.jumpToSection(4);
      expect(c.offset, 500);
      expect(s.currentSection.value, 4);
      // user scrolls away -> lock released
      c.jumpTo(100);
      expect(s.currentSection.value, 0);

      final Future<void> f = s.animateToSection(2);
      await tester.pumpAndSettle();
      await f;
      expect(c.offset, 400);
      expect(s.currentSection.value, 2);

      s.jumpToSection(99); // ignored
      expect(c.offset, 400);
    });
  });
}
