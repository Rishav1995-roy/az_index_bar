import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all labels when they fit', () {
    final List<AzBarSlot> s =
        computeBarSlots(labelCount: 27, availableHeight: 500, minExtent: 16);
    expect(s.length, 27);
    expect(s.every((AzBarSlot e) => !e.isDot), isTrue);
    expect(s.map((AzBarSlot e) => e.labelIndex),
        List<int>.generate(27, (int i) => i));
  });

  test('compact mode alternates labels and dots and keeps first/last', () {
    final List<AzBarSlot> s =
        computeBarSlots(labelCount: 27, availableHeight: 160, minExtent: 16);
    expect(s.length, lessThanOrEqualTo(10));
    expect(s.first, const AzBarSlot(labelIndex: 0, isDot: false));
    expect(s.last, const AzBarSlot(labelIndex: 26, isDot: false));
    for (int i = 0; i < s.length; i++) {
      expect(s[i].isDot, i.isOdd);
    }
    // indexes strictly increase
    for (int i = 1; i < s.length; i++) {
      expect(s[i].labelIndex > s[i - 1].labelIndex, isTrue);
    }
  });

  test('extremely short bars still keep two labels', () {
    final List<AzBarSlot> s =
        computeBarSlots(labelCount: 27, availableHeight: 10, minExtent: 16);
    expect(s.first.labelIndex, 0);
    expect(s.last.labelIndex, 26);
  });

  test('degenerate input', () {
    expect(computeBarSlots(labelCount: 0, availableHeight: 100, minExtent: 16),
        isEmpty);
    expect(
      computeBarSlots(
              labelCount: 3, availableHeight: double.infinity, minExtent: 16)
          .length,
      3,
    );
  });

  test('AzBarSlot equality and toString', () {
    expect(const AzBarSlot(labelIndex: 1, isDot: true),
        const AzBarSlot(labelIndex: 1, isDot: true));
    expect(const AzBarSlot(labelIndex: 1, isDot: true).hashCode,
        const AzBarSlot(labelIndex: 1, isDot: true).hashCode);
    expect(const AzBarSlot(labelIndex: 1, isDot: true).toString(),
        contains('dot'));
  });
}
