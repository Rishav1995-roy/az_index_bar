import 'package:flutter/material.dart';

/// Visual settings for `AzIndexBar`. Every field is optional; missing values
/// are derived from the ambient [Theme].
@immutable
class AzIndexBarThemeData {
  /// Creates a theme. All arguments are optional.
  const AzIndexBarThemeData({
    this.width,
    this.minLabelExtent,
    this.maxLabelExtent,
    this.padding,
    this.backgroundColor,
    this.activeBackgroundColor,
    this.borderRadius,
    this.labelStyle,
    this.activeLabelStyle,
    this.disabledLabelStyle,
    this.dotColor,
    this.dotSize,
    this.bubbleSize,
    this.bubbleColor,
    this.bubbleShape,
    this.bubbleTextStyle,
    this.bubbleGap,
    this.activeShape,
  });

  /// Bar width. Default 28.
  final double? width;

  /// Smallest height one label may get before the bar collapses into
  /// compact mode (dots). Default 16.
  final double? minLabelExtent;

  /// Largest height of one label; extra space is left empty and the labels
  /// are centred. Default 22.
  final double? maxLabelExtent;

  /// Padding inside the bar background. Default 2 vertical, 0 horizontal.
  final EdgeInsetsGeometry? padding;

  /// Background of the bar (transparent by default).
  final Color? backgroundColor;

  /// Fill behind the highlighted label. Defaults to the primary colour.
  final Color? activeBackgroundColor;

  /// Corner radius of the bar background. Default fully rounded.
  final BorderRadiusGeometry? borderRadius;

  /// Style of a normal label.
  final TextStyle? labelStyle;

  /// Style of the highlighted label.
  final TextStyle? activeLabelStyle;

  /// Style of a label with no items.
  final TextStyle? disabledLabelStyle;

  /// Colour of compact-mode dots.
  final Color? dotColor;

  /// Diameter of compact-mode dots. Default 4.
  final double? dotSize;

  /// Edge length of the floating bubble. Default 56.
  final double? bubbleSize;

  /// Bubble fill. Defaults to the primary colour.
  final Color? bubbleColor;

  /// Bubble shape. Default a rounded square.
  final ShapeBorder? bubbleShape;

  /// Bubble text style.
  final TextStyle? bubbleTextStyle;

  /// Gap between the bar and the bubble. Default 12.
  final double? bubbleGap;

  /// Shape of the highlight behind the active label. Default a circle.
  final ShapeBorder? activeShape;

  /// Copy with some fields replaced.
  AzIndexBarThemeData copyWith({
    double? width,
    double? minLabelExtent,
    double? maxLabelExtent,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? activeBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    TextStyle? labelStyle,
    TextStyle? activeLabelStyle,
    TextStyle? disabledLabelStyle,
    Color? dotColor,
    double? dotSize,
    double? bubbleSize,
    Color? bubbleColor,
    ShapeBorder? bubbleShape,
    TextStyle? bubbleTextStyle,
    double? bubbleGap,
    ShapeBorder? activeShape,
  }) =>
      AzIndexBarThemeData(
        width: width ?? this.width,
        minLabelExtent: minLabelExtent ?? this.minLabelExtent,
        maxLabelExtent: maxLabelExtent ?? this.maxLabelExtent,
        padding: padding ?? this.padding,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        activeBackgroundColor:
            activeBackgroundColor ?? this.activeBackgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        labelStyle: labelStyle ?? this.labelStyle,
        activeLabelStyle: activeLabelStyle ?? this.activeLabelStyle,
        disabledLabelStyle: disabledLabelStyle ?? this.disabledLabelStyle,
        dotColor: dotColor ?? this.dotColor,
        dotSize: dotSize ?? this.dotSize,
        bubbleSize: bubbleSize ?? this.bubbleSize,
        bubbleColor: bubbleColor ?? this.bubbleColor,
        bubbleShape: bubbleShape ?? this.bubbleShape,
        bubbleTextStyle: bubbleTextStyle ?? this.bubbleTextStyle,
        bubbleGap: bubbleGap ?? this.bubbleGap,
        activeShape: activeShape ?? this.activeShape,
      );

  /// Values of [other] win where they are non-null.
  AzIndexBarThemeData merge(AzIndexBarThemeData? other) {
    if (other == null) return this;
    return copyWith(
      width: other.width,
      minLabelExtent: other.minLabelExtent,
      maxLabelExtent: other.maxLabelExtent,
      padding: other.padding,
      backgroundColor: other.backgroundColor,
      activeBackgroundColor: other.activeBackgroundColor,
      borderRadius: other.borderRadius,
      labelStyle: other.labelStyle,
      activeLabelStyle: other.activeLabelStyle,
      disabledLabelStyle: other.disabledLabelStyle,
      dotColor: other.dotColor,
      dotSize: other.dotSize,
      bubbleSize: other.bubbleSize,
      bubbleColor: other.bubbleColor,
      bubbleShape: other.bubbleShape,
      bubbleTextStyle: other.bubbleTextStyle,
      bubbleGap: other.bubbleGap,
      activeShape: other.activeShape,
    );
  }

  /// Fills every missing value from [context]'s [Theme].
  AzIndexBarThemeData resolve(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme c = t.colorScheme;
    final TextStyle base = (t.textTheme.labelSmall ?? const TextStyle())
        .copyWith(fontSize: 11, fontWeight: FontWeight.w600);
    return AzIndexBarThemeData(
      width: width ?? 28,
      minLabelExtent: minLabelExtent ?? 16,
      maxLabelExtent: maxLabelExtent ?? 22,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 2),
      backgroundColor: backgroundColor ?? Colors.transparent,
      activeBackgroundColor: activeBackgroundColor ?? c.primary,
      borderRadius: borderRadius ?? BorderRadius.circular(14),
      labelStyle: base.copyWith(color: c.primary).merge(labelStyle),
      activeLabelStyle:
          base.copyWith(color: c.onPrimary).merge(activeLabelStyle),
      disabledLabelStyle: base
          .copyWith(color: c.onSurface.withValues(alpha: 0.28))
          .merge(disabledLabelStyle),
      dotColor: dotColor ?? c.primary.withValues(alpha: 0.6),
      dotSize: dotSize ?? 4,
      bubbleSize: bubbleSize ?? 56,
      bubbleColor: bubbleColor ?? c.primary,
      bubbleShape: bubbleShape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      bubbleTextStyle: (t.textTheme.headlineSmall ?? const TextStyle())
          .copyWith(color: c.onPrimary, fontWeight: FontWeight.w700)
          .merge(bubbleTextStyle),
      bubbleGap: bubbleGap ?? 12,
      activeShape: activeShape ?? const CircleBorder(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AzIndexBarThemeData &&
      other.width == width &&
      other.minLabelExtent == minLabelExtent &&
      other.maxLabelExtent == maxLabelExtent &&
      other.padding == padding &&
      other.backgroundColor == backgroundColor &&
      other.activeBackgroundColor == activeBackgroundColor &&
      other.borderRadius == borderRadius &&
      other.labelStyle == labelStyle &&
      other.activeLabelStyle == activeLabelStyle &&
      other.disabledLabelStyle == disabledLabelStyle &&
      other.dotColor == dotColor &&
      other.dotSize == dotSize &&
      other.bubbleSize == bubbleSize &&
      other.bubbleColor == bubbleColor &&
      other.bubbleShape == bubbleShape &&
      other.bubbleTextStyle == bubbleTextStyle &&
      other.bubbleGap == bubbleGap &&
      other.activeShape == activeShape;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        width,
        minLabelExtent,
        maxLabelExtent,
        padding,
        backgroundColor,
        activeBackgroundColor,
        borderRadius,
        labelStyle,
        activeLabelStyle,
        disabledLabelStyle,
        dotColor,
        dotSize,
        bubbleSize,
        bubbleColor,
        bubbleShape,
        bubbleTextStyle,
        bubbleGap,
        activeShape,
      ]);
}

/// Provides an [AzIndexBarThemeData] to every `AzIndexBar` below it.
class AzIndexBarTheme extends InheritedWidget {
  /// Creates a theme scope.
  const AzIndexBarTheme({super.key, required this.data, required super.child});

  /// The theme data.
  final AzIndexBarThemeData data;

  /// The nearest theme data, or an empty one.
  static AzIndexBarThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AzIndexBarTheme>()?.data ??
      const AzIndexBarThemeData();

  @override
  bool updateShouldNotify(AzIndexBarTheme oldWidget) => data != oldWidget.data;
}
