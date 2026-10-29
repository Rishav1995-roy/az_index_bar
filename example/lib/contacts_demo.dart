import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';

import 'data.dart';

/// A contact list with sticky headers and the index bar (fixed-height
/// items, so section jumps are exact).
class ContactsDemo extends StatefulWidget {
  /// Creates the demo.
  const ContactsDemo({super.key, this.controller, this.theme});

  /// Optional controller, used by the GIF generator.
  final AzSectionedListController? controller;

  /// Optional bar theme.
  final AzIndexBarThemeData? theme;

  @override
  State<ContactsDemo> createState() => _ContactsDemoState();
}

class _ContactsDemoState extends State<ContactsDemo> {
  late final AzGroups<String> groups = AzGroups<String>.from(
    sampleContacts(),
    textOf: (String s) => s,
  );

  static const List<Color> _palette = <Color>[
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AzSectionedListView<String>(
      groups: groups,
      controller: widget.controller,
      barTheme: widget.theme,
      headerExtent: 32,
      itemExtent: 64,
      barPadding: const EdgeInsetsDirectional.only(top: 8, bottom: 8, end: 2),
      headerBuilder: (BuildContext c, AzSection<String> s, int i) => Container(
        color: cs.surfaceContainerHighest,
        padding: const EdgeInsetsDirectional.only(start: 20),
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          s.label,
          style: Theme.of(c).textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      itemBuilder: (BuildContext c, String name, int s, int i) {
        final Color color = _palette[name.hashCode.abs() % _palette.length];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Text(_initial(name)),
          ),
          title: Text(name),
          subtitle: Text(
              '+00 555 01${(name.length * 37 + i).toString().padLeft(2, '0')}'),
        );
      },
    );
  }
}

String _initial(String name) {
  for (final int r in name.runes) {
    final String ch = String.fromCharCode(r);
    if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(ch)) {
      return ch.toUpperCase();
    }
  }
  return '?';
}
