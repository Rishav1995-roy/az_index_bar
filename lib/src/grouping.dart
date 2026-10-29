import 'index_resolver.dart';

/// One non-empty section of an [AzGroups]: a label and its items.
class AzSection<T> {
  /// Creates a section.
  const AzSection(this.label, this.items);

  /// The index label, for example `A`.
  final String label;

  /// Items in this section, already sorted.
  final List<T> items;
}

/// One row of a flattened list: either a section header or an item.
class AzEntry<T> {
  /// Creates an entry. Exactly one of [item] / header is represented by
  /// [isHeader].
  const AzEntry._(this.sectionIndex, this.label, this.item, this.isHeader);

  /// Index of the section (into [AzGroups.sections]).
  final int sectionIndex;

  /// Section label.
  final String label;

  /// The item, or null for a header.
  final T? item;

  /// True for a section header row.
  final bool isHeader;
}

/// Items grouped by index label, ready for a sectioned list and an
/// `AzIndexBar`.
///
/// [labels] always holds the full resolver index (so the bar shows `A..Z#`
/// even if some letters are empty); [enabledLabels] holds only the labels that
/// have items, which is what the bar greys out.
class AzGroups<T> {
  AzGroups._(this.resolver, this.sections)
      : _sectionOfLabel = <String, int>{
          for (int i = 0; i < sections.length; i++) sections[i].label: i,
        };

  /// Groups [items] by the label that [resolver] gives for `textOf(item)`.
  ///
  /// Items are sorted with [AzIndexResolver.compare] unless [sort] is false
  /// (keep your own order inside each section) or [compare] is given.
  factory AzGroups.from(
    Iterable<T> items, {
    required String Function(T item) textOf,
    AzIndexResolver? resolver,
    bool sort = true,
    Comparator<T>? compare,
  }) {
    final AzIndexResolver r = resolver ?? AzIndexResolver.latin();
    final Map<String, List<T>> buckets = <String, List<T>>{};
    for (final T item in items) {
      buckets.putIfAbsent(r.resolve(textOf(item)), () => <T>[]).add(item);
    }
    final List<AzSection<T>> sections = <AzSection<T>>[];
    final Set<String> seen = <String>{};
    final List<String> order = <String>[...r.labels];
    if (!order.contains(r.fallbackLabel)) order.add(r.fallbackLabel);
    for (final String label in order) {
      final List<T>? list = buckets[label];
      if (list == null || list.isEmpty || !seen.add(label)) continue;
      if (compare != null) {
        list.sort(compare);
      } else if (sort) {
        list.sort((T a, T b) => r.compare(textOf(a), textOf(b)));
      }
      sections.add(AzSection<T>(label, list));
    }
    return AzGroups<T>._(r, sections);
  }

  /// The resolver used.
  final AzIndexResolver resolver;

  /// Non-empty sections in index order.
  final List<AzSection<T>> sections;

  final Map<String, int> _sectionOfLabel;

  /// The full list of labels for the bar, including empty ones.
  List<String> get labels => resolver.labels;

  /// Labels that have at least one item.
  Set<String> get enabledLabels => _sectionOfLabel.keys.toSet();

  /// Total number of items.
  int get itemCount =>
      sections.fold<int>(0, (int sum, AzSection<T> s) => sum + s.items.length);

  /// Item counts per section, in order.
  List<int> get itemCounts =>
      <int>[for (final AzSection<T> s in sections) s.items.length];

  /// Index into [sections] for [label], or -1 if that label is empty.
  int sectionIndexOfLabel(String label) => _sectionOfLabel[label] ?? -1;

  /// Index of the first section at or after [label] in bar order, or the last
  /// section before it when none follows. -1 when there are no sections.
  int nearestSectionIndexOfLabel(String label) {
    final int pos = labels.indexOf(label);
    if (pos < 0 || sections.isEmpty) return -1;
    for (int i = pos; i < labels.length; i++) {
      final int s = sectionIndexOfLabel(labels[i]);
      if (s >= 0) return s;
    }
    for (int i = pos - 1; i >= 0; i--) {
      final int s = sectionIndexOfLabel(labels[i]);
      if (s >= 0) return s;
    }
    return -1;
  }

  /// Index in the flattened list for the first row of section [sectionIndex].
  ///
  /// With [withHeaders] (default) each section contributes a header row
  /// before its items, matching [flatten]. Use this to drive any indexed list
  /// such as `scrollable_positioned_list` from `AzIndexBar.onIndexSelected`.
  int flatIndexOfSection(int sectionIndex, {bool withHeaders = true}) {
    int index = 0;
    for (int i = 0; i < sectionIndex; i++) {
      index += sections[i].items.length + (withHeaders ? 1 : 0);
    }
    return index;
  }

  /// Same as [flatIndexOfSection] but addressed by bar label. Returns -1 for
  /// an empty label.
  int flatIndexOfLabel(String label, {bool withHeaders = true}) {
    final int s = sectionIndexOfLabel(label);
    return s < 0 ? -1 : flatIndexOfSection(s, withHeaders: withHeaders);
  }

  /// Section index of the flattened row [flatIndex] (with headers).
  int sectionIndexOfFlatIndex(int flatIndex, {bool withHeaders = true}) {
    int remaining = flatIndex;
    for (int i = 0; i < sections.length; i++) {
      final int size = sections[i].items.length + (withHeaders ? 1 : 0);
      if (remaining < size) return i;
      remaining -= size;
    }
    return sections.isEmpty ? -1 : sections.length - 1;
  }

  /// Headers and items as one flat list.
  List<AzEntry<T>> flatten({bool withHeaders = true}) => <AzEntry<T>>[
        for (int i = 0; i < sections.length; i++) ...<AzEntry<T>>[
          if (withHeaders) AzEntry<T>._(i, sections[i].label, null, true),
          for (final T item in sections[i].items)
            AzEntry<T>._(i, sections[i].label, item, false),
        ],
      ];
}
