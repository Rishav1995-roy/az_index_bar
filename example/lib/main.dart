import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter/material.dart';

import 'contacts_demo.dart';
import 'data.dart';

void main() => runApp(const ExampleApp());

/// The example app: contacts, alphabets, theming and bring-your-own-list.
class ExampleApp extends StatelessWidget {
  /// Creates the app.
  const ExampleApp({super.key, this.seed = const Color(0xFF3F51B5)});

  /// Theme seed colour.
  final Color seed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'az_index_bar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

/// Bottom-navigation shell with the four demo screens.
class HomeShell extends StatefulWidget {
  /// Creates the shell.
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Contacts',
    'Alphabets',
    'Theming',
    'Your own list',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const ContactsDemo(),
      const AlphabetsPage(),
      const ThemingPage(),
      const OwnListPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
              icon: Icon(Icons.contacts_outlined), label: 'Contacts'),
          NavigationDestination(
              icon: Icon(Icons.translate), label: 'Alphabets'),
          NavigationDestination(
              icon: Icon(Icons.palette_outlined), label: 'Theming'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Own list'),
        ],
      ),
    );
  }
}

Widget _header(BuildContext c, AzSection<String> s, int i) {
  final ColorScheme cs = Theme.of(c).colorScheme;
  return Container(
    color: cs.surfaceContainerHighest,
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsetsDirectional.only(start: 20),
    child: Text(s.label,
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
  );
}

/// Non-Latin and custom indexes: Cyrillic, Greek, Devanagari, Korean,
/// Japanese and Swedish with kept letters.
class AlphabetsPage extends StatefulWidget {
  /// Creates the page.
  const AlphabetsPage({super.key});

  @override
  State<AlphabetsPage> createState() => _AlphabetsPageState();
}

class _AlphabetsPageState extends State<AlphabetsPage> {
  String _script = scriptSamples.keys.first;

  AzIndexResolver _resolver(String script) {
    switch (script) {
      case 'Cyrillic':
        return AzIndexResolver.cyrillic();
      case 'Greek':
        return AzIndexResolver.greek();
      case 'Devanagari':
        return AzIndexResolver.devanagari();
      case 'Korean':
        return AzIndexResolver.korean();
      case 'Japanese':
        return AzIndexResolver.japanese();
      default:
        return AzIndexResolver.latin(
          preserve: <String>{'Å', 'Ä', 'Ö'},
          extraLabels: <String>['Å', 'Ä', 'Ö'],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AzGroups<String> g = AzGroups<String>.from(
      scriptSamples[_script]!,
      textOf: (String s) => s,
      resolver: _resolver(_script),
    );
    return Column(
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: <Widget>[
              for (final String s in scriptSamples.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: s == _script,
                    onSelected: (_) => setState(() => _script = s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AzSectionedListView<String>(
            key: ValueKey<String>(_script),
            groups: g,
            itemExtent: 56,
            headerBuilder: _header,
            itemBuilder: (BuildContext c, String n, int s, int i) =>
                ListTile(title: Text(n)),
          ),
        ),
      ],
    );
  }
}

/// Live theming playground: every knob of [AzIndexBarThemeData], bar height
/// (compact mode), text direction, haptics and disabled-label behaviour.
class ThemingPage extends StatefulWidget {
  /// Creates the page.
  const ThemingPage({super.key});

  @override
  State<ThemingPage> createState() => _ThemingPageState();
}

class _ThemingPageState extends State<ThemingPage> {
  double _width = 28;
  double _bubble = 56;
  double _height = 1; // 0..1 of available height
  bool _rtl = false;
  bool _haptics = true;
  bool _sticky = true;
  bool _square = true;
  int _color = 0;
  AzDisabledBehavior _behavior = AzDisabledBehavior.snapToNext;

  static const List<Color> _colors = <Color>[
    Color(0xFF3F51B5),
    Color(0xFFE91E63),
    Color(0xFF009688),
    Color(0xFFFF6F00),
  ];

  late final AzGroups<String> _groups =
      AzGroups<String>.from(sampleContacts(), textOf: (String s) => s);

  @override
  Widget build(BuildContext context) {
    final Color c = _colors[_color];
    final AzIndexBarThemeData theme = AzIndexBarThemeData(
      width: _width,
      bubbleSize: _bubble,
      activeBackgroundColor: c,
      bubbleColor: c,
      labelStyle:
          TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      dotColor: c.withValues(alpha: 0.6),
      backgroundColor: c.withValues(alpha: 0.08),
      bubbleShape: _square
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
          : const CircleBorder(),
    );
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(builder: (BuildContext _, BoxConstraints box) {
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: (box.maxHeight * _height).clamp(120.0, box.maxHeight),
                  child: AzSectionedListView<String>(
                    groups: _groups,
                    itemExtent: 52,
                    barTheme: theme,
                    stickyHeaders: _sticky,
                    hapticFeedback: _haptics,
                    disabledBehavior: _behavior,
                    barPadding:
                        const EdgeInsetsDirectional.only(top: 4, bottom: 4),
                    headerBuilder: _header,
                    itemBuilder: (BuildContext c, String n, int s, int i) =>
                        ListTile(dense: true, title: Text(n)),
                  ),
                ),
              );
            }),
          ),
          Material(
            elevation: 6,
            child: SizedBox(
              height: 230,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  _slider(
                      'Bar width', _width, 20, 48, (double v) => _width = v),
                  _slider('Bubble size', _bubble, 36, 90,
                      (double v) => _bubble = v),
                  _slider('Bar height (compact mode below ~440)', _height, 0.2,
                      1, (double v) => _height = v),
                  Wrap(spacing: 8, children: <Widget>[
                    for (int i = 0; i < _colors.length; i++)
                      ChoiceChip(
                        label: const Text(' '),
                        avatar: CircleAvatar(backgroundColor: _colors[i]),
                        selected: _color == i,
                        onSelected: (_) => setState(() => _color = i),
                      ),
                  ]),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Right-to-left'),
                    value: _rtl,
                    onChanged: (bool v) => setState(() => _rtl = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Haptics'),
                    value: _haptics,
                    onChanged: (bool v) => setState(() => _haptics = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Sticky headers'),
                    value: _sticky,
                    onChanged: (bool v) => setState(() => _sticky = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Square bubble'),
                    value: _square,
                    onChanged: (bool v) => setState(() => _square = v),
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('Disabled letters'),
                    trailing: DropdownButton<AzDisabledBehavior>(
                      value: _behavior,
                      onChanged: (AzDisabledBehavior? v) =>
                          setState(() => _behavior = v!),
                      items: <DropdownMenuItem<AzDisabledBehavior>>[
                        for (final AzDisabledBehavior b
                            in AzDisabledBehavior.values)
                          DropdownMenuItem<AzDisabledBehavior>(
                              value: b, child: Text(b.name)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double v, double min, double max,
      double Function(double) set) {
    return Row(
      children: <Widget>[
        SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: v,
            min: min,
            max: max,
            onChanged: (double x) => setState(() => set(x)),
          ),
        ),
      ],
    );
  }
}

/// Using the bar with your own `ListView`, a plain `ScrollController` and
/// [AzSectionScroller]; no AzSectionedListView involved. Items here have
/// the same height, so [AzFixedSectionMetrics] is exact. The log shows the
/// generic `onIndexSelected` callback, which is all you need to drive any
/// other list (for example scrollable_positioned_list).
class OwnListPage extends StatefulWidget {
  /// Creates the page.
  const OwnListPage({super.key});

  @override
  State<OwnListPage> createState() => _OwnListPageState();
}

class _OwnListPageState extends State<OwnListPage> {
  final ScrollController _controller = ScrollController();
  late final AzSectionScroller _scroller;
  late final AzGroups<String> _groups =
      AzGroups<String>.from(sampleContacts(), textOf: (String s) => s);
  String _log = 'Touch the bar...';

  static const double _header = 28, _item = 48;

  @override
  void initState() {
    super.initState();
    _scroller = AzSectionScroller(
      controller: _controller,
      metrics: AzFixedSectionMetrics(
        itemCounts: _groups.itemCounts,
        headerExtent: _header,
        itemExtent: _item,
      ),
    );
  }

  @override
  void dispose() {
    _scroller.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A flat ListView: a header row then its items, for every section.
    final List<AzEntry<String>> flat = _groups.flatten();
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ListView.builder(
            controller: _controller,
            padding: const EdgeInsetsDirectional.only(end: 32),
            itemCount: flat.length,
            itemBuilder: (BuildContext c, int i) {
              final AzEntry<String> e = flat[i];
              return SizedBox(
                height: e.isHeader ? _header : _item,
                child: e.isHeader
                    ? ColoredBox(
                        color: Theme.of(c).colorScheme.surfaceContainerHighest,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 16),
                            child: Text(e.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )
                    : ListTile(dense: true, title: Text(e.item!)),
              );
            },
          ),
        ),
        PositionedDirectional(
          end: 0,
          top: 0,
          bottom: 0,
          child: ValueListenableBuilder<int>(
            valueListenable: _scroller.currentSection,
            builder: (BuildContext c, int cur, Widget? _) => AzIndexBar(
              labels: _groups.labels,
              enabledLabels: _groups.enabledLabels,
              currentLabel: _groups.sections[cur].label,
              onIndexSelected: (int index, String label) {
                setState(() => _log =
                    'onIndexSelected(index: $index, label: "$label") -> flat row ${_groups.flatIndexOfLabel(label)}');
                _scroller.jumpToSection(_groups.sectionIndexOfLabel(label));
              },
            ),
          ),
        ),
        PositionedDirectional(
          start: 12,
          bottom: 12,
          child: Material(
            color: Theme.of(context).colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_log,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onInverseSurface)),
            ),
          ),
        ),
      ],
    );
  }
}
