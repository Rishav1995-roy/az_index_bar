import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic names: letters A..Z except [skip], `perLetter + (code % 4)` each.
List<String> syntheticNames({
  Set<String> skip = const <String>{'Q', 'X'},
  int perLetter = 4,
}) {
  final List<String> out = <String>[];
  for (int c = 0x41; c <= 0x5A; c++) {
    final String l = String.fromCharCode(c);
    if (skip.contains(l)) continue;
    for (int k = 0; k < perLetter + c % 4; k++) {
      out.add('${l}ex Sample $k');
    }
  }
  return out;
}

Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness, useMaterial3: true),
      builder: (BuildContext c, Widget? w) =>
          Directionality(textDirection: direction, child: w!),
      home: Scaffold(body: child),
    );

/// A bar alone, at the end edge, [height] tall.
Widget barHost({
  required List<String> labels,
  required void Function(int, String) onSelected,
  double height = 600,
  Set<String>? enabled,
  String? current,
  VoidCallback? onHaptic,
  bool haptics = true,
  AzDisabledBehavior behavior = AzDisabledBehavior.snapToNext,
  AzIndexBarThemeData? theme,
  VoidCallback? onStart,
  VoidCallback? onEnd,
  TextDirection direction = TextDirection.ltr,
}) =>
    host(
      Stack(
        children: <Widget>[
          PositionedDirectional(
            end: 0,
            top: 0,
            height: height,
            child: AzIndexBar(
              labels: labels,
              enabledLabels: enabled,
              currentLabel: current,
              onIndexSelected: onSelected,
              onHaptic: onHaptic,
              hapticFeedback: haptics,
              disabledBehavior: behavior,
              theme: theme,
              onSelectionStart: onStart,
              onSelectionEnd: onEnd,
            ),
          ),
        ],
      ),
      direction: direction,
    );

Finder barText(String t) =>
    find.descendant(of: find.byType(AzIndexBar), matching: find.text(t));

final List<String> alphabet = AzIndexResolver.latin().labels;
