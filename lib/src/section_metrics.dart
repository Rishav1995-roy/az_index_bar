import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Knows where each section starts, in scroll pixels.
///
/// This is what lets a plain `ScrollController` jump to "section K" without
/// `scrollable_positioned_list`. Implementations: [AzFixedSectionMetrics]
/// (equal item heights), [AzExtentSectionMetrics] (you know every section's
/// height) and the measured metrics `AzSectionedListView` uses internally.
abstract class AzSectionMetrics {
  /// Number of sections.
  int get sectionCount;

  /// Scroll offset at which [section] starts. May be an estimate when
  /// [isExact] is false.
  double offsetOfSection(int section);

  /// The section occupying [offset] (the last section starting at or before
  /// it). Returns 0 for an empty or not-yet-measured list.
  int sectionAtOffset(double offset);

  /// True when [offsetOfSection] is exact, so one jump is enough.
  bool get isExact => true;
}

/// Metrics from explicit per-section heights (header + items + padding).
class AzExtentSectionMetrics extends AzSectionMetrics {
  /// Creates metrics. [sectionExtents] is the full main-axis extent of each
  /// section; [leadingExtent] is anything above the first section (a search
  /// field, a list padding).
  AzExtentSectionMetrics(List<double> sectionExtents,
      {double leadingExtent = 0})
      : _offsets = _prefix(sectionExtents, leadingExtent);

  final List<double> _offsets;

  static List<double> _prefix(List<double> extents, double lead) {
    final List<double> o = <double>[];
    double acc = lead;
    for (final double e in extents) {
      o.add(acc);
      acc += e;
    }
    return o;
  }

  @override
  int get sectionCount => _offsets.length;

  @override
  double offsetOfSection(int section) => _offsets[section];

  @override
  int sectionAtOffset(double offset) {
    if (_offsets.isEmpty) return 0;
    int lo = 0, hi = _offsets.length - 1;
    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (_offsets[mid] <= offset + 0.5) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}

/// Metrics for lists whose items all have the same height.
class AzFixedSectionMetrics extends AzExtentSectionMetrics {
  /// [itemCounts] is the number of items per section.
  AzFixedSectionMetrics({
    required List<int> itemCounts,
    required double headerExtent,
    required double itemExtent,
    super.leadingExtent,
  }) : super(
          <double>[
            for (final int c in itemCounts) headerExtent + c * itemExtent
          ],
        );
}

/// Jumps a plain [ScrollController] to sections and tracks which section is
/// at the top.
///
/// ```dart
/// final scroller = AzSectionScroller(controller: scrollController, metrics: metrics);
/// AzIndexBar(onIndexSelected: (i, label) => scroller.jumpToSection(groups.sectionIndexOfLabel(label)), ...)
/// ```
class AzSectionScroller {
  /// Creates a scroller and starts listening to [controller].
  AzSectionScroller({
    required this.controller,
    required AzSectionMetrics metrics,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
  }) : _metrics = metrics {
    controller.addListener(_onScroll);
  }

  /// The controller being driven. It must be attached to a scrollable.
  final ScrollController controller;

  /// Duration of [animateToSection].
  final Duration duration;

  /// Curve of [animateToSection].
  final Curve curve;

  AzSectionMetrics _metrics;
  final ValueNotifier<int> _current = ValueNotifier<int>(0);
  int? _lockedSection;
  double _lockedOffset = 0;
  int _jumpToken = 0;

  /// Replace the metrics when the data changes.
  set metrics(AzSectionMetrics value) {
    _metrics = value;
    _onScroll();
  }

  /// The metrics in use.
  AzSectionMetrics get metrics => _metrics;

  /// The section at the top of the viewport. When the list cannot scroll far
  /// enough to bring a short last section to the top, the section the user
  /// jumped to stays current until they scroll away.
  ValueListenable<int> get currentSection => _current;

  void _onScroll() {
    if (!controller.hasClients || _metrics.sectionCount == 0) return;
    final double offset = controller.offset;
    if (_lockedSection != null) {
      if ((offset - _lockedOffset).abs() < 1) {
        _current.value = _lockedSection!;
        return;
      }
      _lockedSection = null;
    }
    _current.value = _metrics.sectionAtOffset(offset);
  }

  double _clamped(double target) {
    final ScrollPosition p = controller.position;
    return target.clamp(p.minScrollExtent, p.maxScrollExtent);
  }

  /// Jumps so that [section] starts at the top.
  void jumpToSection(int section) {
    if (!controller.hasClients ||
        section < 0 ||
        section >= _metrics.sectionCount) {
      return;
    }
    final int token = ++_jumpToken;
    controller.jumpTo(_clamped(_metrics.offsetOfSection(section)));
    _lock(section);
    if (!_metrics.isExact) unawaited(_refine(section, token));
  }

  /// Animates so that [section] starts at the top.
  Future<void> animateToSection(int section) async {
    if (!controller.hasClients ||
        section < 0 ||
        section >= _metrics.sectionCount) {
      return;
    }
    final int token = ++_jumpToken;
    await controller.animateTo(
      _clamped(_metrics.offsetOfSection(section)),
      duration: duration,
      curve: curve,
    );
    if (token != _jumpToken) return;
    _lock(section);
    if (!_metrics.isExact) await _refine(section, token);
  }

  void _lock(int section) {
    _lockedSection = section;
    _lockedOffset = controller.offset;
    _current.value = section;
  }

  // With estimated metrics the first jump lands near the target; once the
  // target is laid out its real offset is known, so correct it.
  Future<void> _refine(int section, int token) async {
    for (int i = 0; i < 6; i++) {
      await SchedulerBinding.instance.endOfFrame;
      if (token != _jumpToken || !controller.hasClients) return;
      final double want = _clamped(_metrics.offsetOfSection(section));
      if ((want - controller.offset).abs() < 0.5) return;
      controller.jumpTo(want);
      _lock(section);
    }
  }

  /// Stops listening. Call from `State.dispose`.
  void dispose() {
    controller.removeListener(_onScroll);
    _current.dispose();
  }
}
