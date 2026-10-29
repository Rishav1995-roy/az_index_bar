import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'grouping.dart';
import 'index_bar.dart';
import 'section_metrics.dart';
import 'theme.dart';

/// Builds one item of an [AzSectionedListView].
typedef AzItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int sectionIndex,
  int indexInSection,
);

/// Builds a section header of an [AzSectionedListView]. It is laid out with
/// exactly `headerExtent` height.
typedef AzHeaderBuilder<T> = Widget Function(
  BuildContext context,
  AzSection<T> section,
  int sectionIndex,
);

/// Controls an [AzSectionedListView] from the outside.
class AzSectionedListController {
  /// Creates a controller; pass [scrollController] to share your own.
  AzSectionedListController({ScrollController? scrollController})
      : scrollController = scrollController ?? ScrollController(),
        _ownsScroll = scrollController == null;

  /// The scroll controller of the list.
  final ScrollController scrollController;
  final bool _ownsScroll;

  /// Index (into `AzGroups.sections`) of the section at the top.
  final ValueNotifier<int> currentSection = ValueNotifier<int>(0);

  AzSectionScroller? _scroller;

  /// Jumps so that [section] starts at the top.
  void jumpToSection(int section) => _scroller?.jumpToSection(section);

  /// Animates so that [section] starts at the top.
  Future<void> animateToSection(int section) async =>
      _scroller?.animateToSection(section);

  /// Releases resources. Call it when you created the controller yourself.
  void dispose() {
    currentSection.dispose();
    if (_ownsScroll) scrollController.dispose();
  }
}

/// A grouped list with sticky section headers and an [AzIndexBar] that
/// jumps a normal [ScrollController]; no extra scrolling package.
///
/// Give [itemExtent] when every item has the same height for exact jumps;
/// otherwise items may have any height and section offsets are measured
/// from the laid-out slivers (refined over a few frames).
class AzSectionedListView<T> extends StatefulWidget {
  /// Creates the list.
  const AzSectionedListView({
    super.key,
    required this.groups,
    required this.itemBuilder,
    required this.headerBuilder,
    this.headerExtent = 32,
    this.itemExtent,
    this.estimatedItemExtent = 56,
    this.stickyHeaders = true,
    this.controller,
    this.physics,
    this.topPadding = 0,
    this.bottomPadding = 0,
    this.showIndexBar = true,
    this.reserveBarSpace = true,
    this.barPadding = EdgeInsetsDirectional.zero,
    this.barTheme,
    this.hapticFeedback = true,
    this.onHaptic,
    this.showBubble = true,
    this.bubbleBuilder,
    this.disabledBehavior = AzDisabledBehavior.snapToNext,
    this.animateJumps = false,
    this.onSectionChanged,
  });

  /// The grouped data.
  final AzGroups<T> groups;

  /// Builds an item.
  final AzItemBuilder<T> itemBuilder;

  /// Builds a header.
  final AzHeaderBuilder<T> headerBuilder;

  /// Height of every header.
  final double headerExtent;

  /// Height of every item, when constant (enables exact jumps).
  final double? itemExtent;

  /// Item height guess used before real heights are known (measured mode).
  final double estimatedItemExtent;

  /// Whether the header of the current section stays pinned at the top.
  final bool stickyHeaders;

  /// Optional external controller.
  final AzSectionedListController? controller;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Space above the first section.
  final double topPadding;

  /// Space below the last section.
  final double bottomPadding;

  /// Whether to show the index bar.
  final bool showIndexBar;

  /// Whether to leave room for the bar on the end side of the list.
  final bool reserveBarSpace;

  /// Outer padding of the bar (top and bottom limit its height).
  final EdgeInsetsDirectional barPadding;

  /// Bar style.
  final AzIndexBarThemeData? barTheme;

  /// See [AzIndexBar.hapticFeedback].
  final bool hapticFeedback;

  /// See [AzIndexBar.onHaptic].
  final VoidCallback? onHaptic;

  /// See [AzIndexBar.showBubble].
  final bool showBubble;

  /// See [AzIndexBar.bubbleBuilder].
  final AzBubbleBuilder? bubbleBuilder;

  /// See [AzIndexBar.disabledBehavior].
  final AzDisabledBehavior disabledBehavior;

  /// Animate instead of jump when the bar is used.
  final bool animateJumps;

  /// Called when the section at the top changes.
  final void Function(int sectionIndex, String label)? onSectionChanged;

  @override
  State<AzSectionedListView<T>> createState() => _AzSectionedListViewState<T>();
}

class _AzSectionedListViewState<T> extends State<AzSectionedListView<T>> {
  late AzSectionedListController _controller;
  late bool _ownsController;
  late AzSectionScroller _scroller;
  final List<GlobalKey> _keys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AzSectionedListController();
    _scroller = AzSectionScroller(
      controller: _controller.scrollController,
      metrics: _buildMetrics(),
    );
    _controller._scroller = _scroller;
    _scroller.currentSection.addListener(_onSection);
  }

  void _detach() {
    _scroller.currentSection.removeListener(_onSection);
    _controller._scroller = null;
    _scroller.dispose();
    if (_ownsController) _controller.dispose();
  }

  void _onSection() {
    final int i = _scroller.currentSection.value;
    _controller.currentSection.value = i;
    final List<AzSection<T>> s = widget.groups.sections;
    if (i >= 0 && i < s.length) widget.onSectionChanged?.call(i, s[i].label);
  }

  AzSectionMetrics _buildMetrics() {
    final AzGroups<T> g = widget.groups;
    while (_keys.length < g.sections.length) {
      _keys.add(GlobalKey());
    }
    if (widget.itemExtent != null) {
      return AzFixedSectionMetrics(
        itemCounts: g.itemCounts,
        headerExtent: widget.headerExtent,
        itemExtent: widget.itemExtent!,
        leadingExtent: widget.topPadding,
      );
    }
    return _MeasuredMetrics(
      keys: _keys,
      counts: g.itemCounts,
      headerExtent: widget.headerExtent,
      estimatedItemExtent: widget.estimatedItemExtent,
      leading: widget.topPadding,
    );
  }

  @override
  void didUpdateWidget(AzSectionedListView<T> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _detach();
      _attach();
    } else {
      _scroller.metrics = _buildMetrics();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _onIndexSelected(int _, String label) {
    final int s = widget.groups.sectionIndexOfLabel(label);
    if (s < 0) return;
    if (widget.animateJumps) {
      _scroller.animateToSection(s);
    } else {
      _scroller.jumpToSection(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AzGroups<T> g = widget.groups;
    _buildMetrics(); // make sure keys exist for every section
    final AzIndexBarThemeData barTheme =
        AzIndexBarTheme.of(context).merge(widget.barTheme).resolve(context);
    final double reserve =
        widget.showIndexBar && widget.reserveBarSpace ? barTheme.width! : 0;

    final Widget list = CustomScrollView(
      controller: _controller.scrollController,
      physics: widget.physics,
      slivers: <Widget>[
        if (widget.topPadding > 0)
          SliverToBoxAdapter(child: SizedBox(height: widget.topPadding)),
        for (int s = 0; s < g.sections.length; s++)
          SliverMainAxisGroup(
            key: _keys[s],
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: widget.stickyHeaders,
                delegate: _HeaderDelegate(
                  extent: widget.headerExtent,
                  child: widget.headerBuilder(context, g.sections[s], s),
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.only(end: reserve),
                sliver: _items(s),
              ),
            ],
          ),
        if (widget.bottomPadding > 0)
          SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
      ],
    );

    if (!widget.showIndexBar) return list;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: list),
        PositionedDirectional(
          end: widget.barPadding.end,
          top: widget.barPadding.top,
          bottom: widget.barPadding.bottom,
          child: ValueListenableBuilder<int>(
            valueListenable: _controller.currentSection,
            builder: (BuildContext context, int current, Widget? _) {
              return AzIndexBar(
                labels: g.labels,
                enabledLabels: g.enabledLabels,
                currentLabel: current < g.sections.length
                    ? g.sections[current].label
                    : null,
                onIndexSelected: _onIndexSelected,
                hapticFeedback: widget.hapticFeedback,
                onHaptic: widget.onHaptic,
                showBubble: widget.showBubble,
                bubbleBuilder: widget.bubbleBuilder,
                disabledBehavior: widget.disabledBehavior,
                theme: widget.barTheme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _items(int s) {
    final AzSection<T> section = widget.groups.sections[s];
    Widget build(BuildContext c, int i) =>
        widget.itemBuilder(c, section.items[i], s, i);
    if (widget.itemExtent != null) {
      return SliverFixedExtentList.builder(
        itemExtent: widget.itemExtent!,
        itemCount: section.items.length,
        itemBuilder: build,
      );
    }
    return SliverList.builder(
      itemCount: section.items.length,
      itemBuilder: build,
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: extent, child: child);

  @override
  bool shouldRebuild(_HeaderDelegate old) => true;
}

/// Offsets read from the laid-out section slivers.
class _MeasuredMetrics extends AzSectionMetrics {
  _MeasuredMetrics({
    required this.keys,
    required this.counts,
    required this.headerExtent,
    required this.estimatedItemExtent,
    required this.leading,
  });

  final List<GlobalKey> keys;
  final List<int> counts;
  final double headerExtent;
  final double estimatedItemExtent;
  final double leading;

  @override
  int get sectionCount => counts.length;

  @override
  bool get isExact => false;

  double? _known(int i) {
    final RenderObject? ro = keys[i].currentContext?.findRenderObject();
    if (ro is RenderSliver && ro.attached && ro.geometry != null) {
      return ro.constraints.precedingScrollExtent;
    }
    return null;
  }

  @override
  double offsetOfSection(int section) {
    final double? k = _known(section);
    if (k != null) return k;
    int j = section - 1;
    double? base;
    while (j >= 0 && (base = _known(j)) == null) {
      j--;
    }
    double offset = base ?? leading;
    for (int s = j < 0 ? 0 : j; s < section; s++) {
      offset += headerExtent + counts[s] * estimatedItemExtent;
    }
    return offset;
  }

  @override
  int sectionAtOffset(double offset) {
    for (int i = counts.length - 1; i >= 0; i--) {
      final double? k = _known(i);
      if (k != null && k <= offset + 0.5) return i;
    }
    return 0;
  }
}
