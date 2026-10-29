import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bar_slots.dart';
import 'theme.dart';

/// What happens when the finger is over a label that has no items.
enum AzDisabledBehavior {
  /// Nothing: the previous selection (and bubble text) stays.
  ignore,

  /// Select the next label that has items (like the iOS contacts list),
  /// or the previous one when there is none after it.
  snapToNext,

  /// Select the closest label that has items, searching in both directions.
  snapToNearest,
}

/// Builds the bubble that follows the finger.
typedef AzBubbleBuilder = Widget Function(BuildContext context, String label);

/// A vertical index scrubber ("A-Z bar").
///
/// It is a plain widget with no knowledge of any list: it reports the label
/// under the finger through [onIndexSelected] and you scroll whatever you
/// like (a `ScrollController`, `scrollable_positioned_list`, a `PageView`).
/// Pair it with `AzSectionScroller` or use `AzSectionedListView` for a
/// ready-made integration.
///
/// Place it at the edge of a `Stack`, for example with
/// `PositionedDirectional(end: 0, top: 0, bottom: 0, ...)`. It fills the
/// height it is given, centres its labels, and switches to compact mode
/// (dots) when the labels do not fit.
class AzIndexBar extends StatefulWidget {
  /// Creates an index bar.
  const AzIndexBar({
    super.key,
    required this.labels,
    required this.onIndexSelected,
    this.enabledLabels,
    this.currentLabel,
    this.onSelectionStart,
    this.onSelectionEnd,
    this.hapticFeedback = true,
    this.onHaptic,
    this.showBubble = true,
    this.bubbleBuilder,
    this.disabledBehavior = AzDisabledBehavior.snapToNext,
    this.theme,
    this.semanticLabel = 'Section index',
  });

  /// All labels, top to bottom.
  final List<String> labels;

  /// Called whenever the selected label changes while touching (and once on
  /// touch down). Receives the index into [labels] and the label.
  final void Function(int index, String label) onIndexSelected;

  /// Labels that have content; others are drawn disabled. Null enables all.
  final Set<String>? enabledLabels;

  /// Label to highlight while the user is not touching the bar, typically
  /// the section currently at the top of the list.
  final String? currentLabel;

  /// Called when a touch starts on the bar.
  final VoidCallback? onSelectionStart;

  /// Called when the touch ends or is cancelled, always paired with
  /// [onSelectionStart].
  final VoidCallback? onSelectionEnd;

  /// Whether to give haptic feedback when the selected label changes.
  final bool hapticFeedback;

  /// Replaces the default `HapticFeedback.selectionClick`. Called once per
  /// label change when [hapticFeedback] is true.
  final VoidCallback? onHaptic;

  /// Whether to show the floating bubble while touching.
  final bool showBubble;

  /// Custom bubble content (replaces the default square with the label).
  final AzBubbleBuilder? bubbleBuilder;

  /// How labels without content react to touches.
  final AzDisabledBehavior disabledBehavior;

  /// Style overrides; merged over any ambient [AzIndexBarTheme].
  final AzIndexBarThemeData? theme;

  /// Accessibility label of the bar.
  final String semanticLabel;

  @override
  State<AzIndexBar> createState() => _AzIndexBarState();
}

class _AzIndexBarState extends State<AzIndexBar> {
  bool _touching = false;
  int? _selected;
  double _bubbleY = 0;
  int? _pointer;

  // Latest layout, used to map touches.
  List<AzBarSlot> _slots = const <AzBarSlot>[];
  double _slotExtent = 0;
  double _contentTop = 0;

  bool _isEnabled(int i) =>
      widget.enabledLabels == null ||
      widget.enabledLabels!.contains(widget.labels[i]);

  int? _resolveEnabled(int i) {
    if (_isEnabled(i)) return i;
    final int n = widget.labels.length;
    int? next, prev;
    for (int j = i + 1; j < n; j++) {
      if (_isEnabled(j)) {
        next = j;
        break;
      }
    }
    for (int j = i - 1; j >= 0; j--) {
      if (_isEnabled(j)) {
        prev = j;
        break;
      }
    }
    switch (widget.disabledBehavior) {
      case AzDisabledBehavior.ignore:
        return null;
      case AzDisabledBehavior.snapToNext:
        return next ?? prev;
      case AzDisabledBehavior.snapToNearest:
        if (next == null) return prev;
        if (prev == null) return next;
        return (i - prev) < (next - i) ? prev : next;
    }
  }

  void _select(Offset local) {
    if (_slots.isEmpty) return;
    final double y = local.dy - _contentTop;
    final int slotIdx = (y / _slotExtent).floor().clamp(0, _slots.length - 1);
    final int? target = _resolveEnabled(_slots[slotIdx].labelIndex);
    final double bubbleY = (_contentTop + (slotIdx + 0.5) * _slotExtent);
    if (target == null) {
      setState(() => _bubbleY = bubbleY);
      return;
    }
    final bool changed = target != _selected;
    setState(() {
      _selected = target;
      _bubbleY = bubbleY;
    });
    if (changed) _commit(target);
  }

  void _commit(int index) {
    if (widget.hapticFeedback) {
      (widget.onHaptic ?? HapticFeedback.selectionClick).call();
    }
    widget.onIndexSelected(index, widget.labels[index]);
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    setState(() {
      _touching = true;
      _selected = null;
    });
    widget.onSelectionStart?.call();
    _select(e.localPosition);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _select(e.localPosition);
  }

  void _end(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _release();
  }

  void _release() {
    _pointer = null;
    if (!_touching) return;
    if (mounted) setState(() => _touching = false);
    widget.onSelectionEnd?.call();
  }

  @override
  void didUpdateWidget(AzIndexBar old) {
    super.didUpdateWidget(old);
    if (old.labels.length != widget.labels.length) _selected = null;
  }

  @override
  void dispose() {
    if (_touching) widget.onSelectionEnd?.call();
    super.dispose();
  }

  int? _step(int from, int dir) {
    for (int j = from + dir; j >= 0 && j < widget.labels.length; j += dir) {
      if (_isEnabled(j)) return j;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AzIndexBarThemeData t =
        AzIndexBarTheme.of(context).merge(widget.theme).resolve(context);
    final TextDirection dir = Directionality.of(context);
    final EdgeInsets pad = t.padding!.resolve(dir);
    final int current = widget.currentLabel == null
        ? -1
        : widget.labels.indexOf(widget.currentLabel!);
    final int active = _touching && _selected != null ? _selected! : current;

    final String value = active >= 0 ? widget.labels[active] : '';

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: value,
      increasedValue: value.isEmpty ? '' : (_nextLabel(active, 1) ?? value),
      decreasedValue: value.isEmpty ? '' : (_nextLabel(active, -1) ?? value),
      onIncrease: () {
        final int? n = _step(active < 0 ? -1 : active, 1);
        if (n != null) _commit(n);
      },
      onDecrease: () {
        final int? n = _step(active < 0 ? widget.labels.length : active, -1);
        if (n != null) _commit(n);
      },
      child: SizedBox(
        width: t.width,
        child: LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
          final double natural =
              widget.labels.length * t.maxLabelExtent! + pad.vertical;
          final double height = c.hasBoundedHeight ? c.maxHeight : natural;
          final double inner =
              (height - pad.vertical).clamp(0.0, double.infinity);
          _slots = computeBarSlots(
            labelCount: widget.labels.length,
            availableHeight: inner,
            minExtent: t.minLabelExtent!,
          );
          _slotExtent = _slots.isEmpty
              ? 0
              : (inner / _slots.length).clamp(0.0, t.maxLabelExtent!);
          final double contentH = _slotExtent * _slots.length;
          final double top = (height - contentH - pad.vertical) / 2;
          _contentTop = top + pad.top;

          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _down,
                      onPointerMove: _move,
                      onPointerUp: _end,
                      onPointerCancel: _end,
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.center,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.backgroundColor,
                              borderRadius: t.borderRadius,
                            ),
                            child: Padding(
                              padding: pad,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  for (int i = 0; i < _slots.length; i++)
                                    _buildSlot(t, i, active),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_touching && widget.showBubble && _selected != null)
                  _buildBubble(t, height),
              ],
            ),
          );
        }),
      ),
    );
  }

  String? _nextLabel(int from, int dir) {
    final int? n =
        _step(from < 0 ? (dir > 0 ? -1 : widget.labels.length) : from, dir);
    return n == null ? null : widget.labels[n];
  }

  Widget _buildSlot(AzIndexBarThemeData t, int i, int active) {
    final AzBarSlot slot = _slots[i];
    final double box = _slotExtent < t.width! ? _slotExtent : t.width!;
    if (slot.isDot) {
      final int a = _slots[i - 1].labelIndex, b = _slots[i + 1].labelIndex;
      final bool isActive = active > a && active < b;
      final double d = t.dotSize! * (isActive ? 1.5 : 1);
      return SizedBox(
        height: _slotExtent,
        child: Center(
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? t.activeBackgroundColor : t.dotColor,
            ),
          ),
        ),
      );
    }
    final bool isActive = slot.labelIndex == active;
    final bool enabled = _isEnabled(slot.labelIndex);
    final TextStyle style = isActive
        ? t.activeLabelStyle!
        : (enabled ? t.labelStyle! : t.disabledLabelStyle!);
    return SizedBox(
      height: _slotExtent,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: box,
          height: box,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: isActive ? t.activeBackgroundColor : Colors.transparent,
            shape: t.activeShape!,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child:
                Text(widget.labels[slot.labelIndex], style: style, maxLines: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(AzIndexBarThemeData t, double height) {
    final double size = t.bubbleSize!;
    final double top = (_bubbleY - size / 2)
        .clamp(0.0, (height - size).clamp(0.0, double.infinity));
    final String label = widget.labels[_selected!];
    return PositionedDirectional(
      top: top,
      end: t.width! + t.bubbleGap!,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: KeyedSubtree(
            key: const ValueKey<String>('az_bubble'),
            child: widget.bubbleBuilder?.call(context, label) ??
                DecoratedBox(
                  decoration: ShapeDecoration(
                      color: t.bubbleColor, shape: t.bubbleShape!),
                  child: SizedBox.square(
                    dimension: size,
                    child: Center(child: Text(label, style: t.bubbleTextStyle)),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
