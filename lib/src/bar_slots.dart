/// One slot of the index bar: a label or a dot standing for hidden labels.
class AzBarSlot {
  /// Creates a slot.
  const AzBarSlot({required this.labelIndex, required this.isDot});

  /// Index into the label list. For a dot this is the middle one of the
  /// labels it hides, so touching a dot still selects something sensible.
  final int labelIndex;

  /// True when this slot is drawn as a dot.
  final bool isDot;

  @override
  bool operator ==(Object other) =>
      other is AzBarSlot &&
      other.labelIndex == labelIndex &&
      other.isDot == isDot;

  @override
  int get hashCode => Object.hash(labelIndex, isDot);

  @override
  String toString() => 'AzBarSlot($labelIndex${isDot ? ', dot' : ''})';
}

/// Decides which slots the bar draws for [labelCount] labels in
/// [availableHeight].
///
/// When every label fits with at least [minExtent] each, all labels are
/// returned. Otherwise the bar collapses ("compact mode"): labels are
/// sampled evenly (always keeping the first and last) with a dot between
/// each pair, like the iOS contacts index.
List<AzBarSlot> computeBarSlots({
  required int labelCount,
  required double availableHeight,
  required double minExtent,
}) {
  if (labelCount <= 0) return const <AzBarSlot>[];
  final int fit = minExtent <= 0
      ? labelCount
      : (availableHeight.isFinite
          ? (availableHeight / minExtent).floor()
          : labelCount);
  if (fit >= labelCount) {
    return <AzBarSlot>[
      for (int i = 0; i < labelCount; i++)
        AzBarSlot(labelIndex: i, isDot: false),
    ];
  }
  // slots = 2k - 1 with k shown labels; keep at least 2 labels.
  final int k = ((fit + 1) ~/ 2).clamp(2, labelCount);
  final List<int> shown = <int>[
    for (int i = 0; i < k; i++) (i * (labelCount - 1) / (k - 1)).round(),
  ];
  final List<AzBarSlot> out = <AzBarSlot>[];
  for (int i = 0; i < shown.length; i++) {
    out.add(AzBarSlot(labelIndex: shown[i], isDot: false));
    if (i < shown.length - 1) {
      final int a = shown[i], b = shown[i + 1];
      if (b - a > 1) {
        out.add(AzBarSlot(labelIndex: (a + b) ~/ 2, isDot: true));
      }
    }
  }
  return out;
}
