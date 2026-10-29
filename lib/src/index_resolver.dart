import 'folding.dart' as folding;

/// Decides which index label (for example `A` or `#`) a piece of text
/// belongs to, and provides a matching sort order.
///
/// Use one of the presets ([AzIndexResolver.latin], [AzIndexResolver.cyrillic],
/// [AzIndexResolver.greek], [AzIndexResolver.devanagari],
/// [AzIndexResolver.korean], [AzIndexResolver.japanese]) or build your own
/// with the constructor and a [runeMapper].
class AzIndexResolver {
  /// Creates a resolver for a custom index.
  ///
  /// [labels] is the ordered list shown in the bar. [runeMapper] receives the
  /// first non-space code point of the text and may return the label it
  /// belongs to, or null to fall back to the generic rules (case folding,
  /// diacritics folding, then [fallbackLabel]).
  const AzIndexResolver({
    required this.labels,
    this.fallbackLabel = '#',
    this.foldDiacritics = true,
    this.preserve = const <String>{},
    this.runeMapper,
  });

  /// Latin alphabet `A` to `Z` plus [fallbackLabel] (`#`) for digits and
  /// symbols.
  ///
  /// With [foldDiacritics] (default) `Éclair`, `Östen` and `Ñandú` land under
  /// `E`, `O` and `N`. Letters listed in [preserve] keep their own bucket,
  /// for example `{'Å', 'Ä', 'Ö'}` for Swedish; add the same letters to
  /// [extraLabels] so they appear in the bar. Set [hashFirst] to put `#`
  /// before `A`.
  factory AzIndexResolver.latin({
    bool foldDiacritics = true,
    Set<String> preserve = const <String>{},
    List<String> extraLabels = const <String>[],
    bool hashFirst = false,
    String fallbackLabel = '#',
  }) {
    final List<String> letters = <String>[
      for (int c = 0x41; c <= 0x5A; c++) String.fromCharCode(c),
      ...extraLabels,
    ];
    return AzIndexResolver(
      labels: hashFirst
          ? <String>[fallbackLabel, ...letters]
          : <String>[...letters, fallbackLabel],
      foldDiacritics: foldDiacritics,
      preserve: preserve,
      fallbackLabel: fallbackLabel,
    );
  }

  /// Russian/Ukrainian-style Cyrillic index (`А` to `Я`, without the rarely
  /// leading `Ъ`, `Ь`, `Ы`) plus `#`. `Ё` is folded into `Е` and `Й` into `И`.
  factory AzIndexResolver.cyrillic() => AzIndexResolver(
        labels: <String>[
          ...'АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯ'.split(''),
          '#',
        ],
        runeMapper: (int r) {
          final String c = String.fromCharCode(r).toUpperCase();
          if (c == 'Ё') return 'Е';
          if (c == 'Й') return 'И';
          return null;
        },
      );

  /// Modern Greek index (`Α` to `Ω`) plus `#`. Accented capitals such as `Ά`
  /// are folded into their base letter.
  factory AzIndexResolver.greek() => AzIndexResolver(
        labels: <String>[...'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ'.split(''), '#'],
        runeMapper: (int r) {
          final String c = String.fromCharCode(r).toUpperCase();
          const Map<String, String> base = <String, String>{
            'Ά': 'Α',
            'Έ': 'Ε',
            'Ή': 'Η',
            'Ί': 'Ι',
            'Ϊ': 'Ι',
            'Ό': 'Ο',
            'Ύ': 'Υ',
            'Ϋ': 'Υ',
            'Ώ': 'Ω',
            'Ϲ': 'Σ',
          };
          return base[c];
        },
      );

  /// Devanagari index (Hindi/Marathi): vowels `अ` to `औ`, consonants `क` to
  /// `ह`, plus `#`. Nukta consonants (`क़`, `ज़`...) map to their base letter.
  factory AzIndexResolver.devanagari() => AzIndexResolver(
        labels: <String>[
          ...'अआइईउऊऋएऐओऔ'.split(''),
          ...'कखगघचछजझटठडढणतथदधनपफबभमयरलवशषसह'.split(''),
          '#',
        ],
        runeMapper: (int r) {
          const Map<int, String> nukta = <int, String>{
            0x0958: 'क',
            0x0959: 'ख',
            0x095A: 'ग',
            0x095B: 'ज',
            0x095C: 'ड',
            0x095D: 'ढ',
            0x095E: 'फ',
            0x095F: 'य',
          };
          return nukta[r];
        },
      );

  /// Korean index by initial consonant (`ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ
  /// ㅎ`) plus `#`. Double consonants fold into the single one (`ㄲ` -> `ㄱ`).
  factory AzIndexResolver.korean() => AzIndexResolver(
        labels: <String>[
          ...'ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ'.split(''),
          '#',
        ],
        runeMapper: (int r) {
          if (r < 0xAC00 || r > 0xD7A3) return null;
          const String initials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
          const Map<String, String> fold = <String, String>{
            'ㄲ': 'ㄱ',
            'ㄸ': 'ㄷ',
            'ㅃ': 'ㅂ',
            'ㅆ': 'ㅅ',
            'ㅉ': 'ㅈ',
          };
          final String initial = initials[(r - 0xAC00) ~/ 588];
          return fold[initial] ?? initial;
        },
      );

  /// Japanese gojuon index (`あ か さ た な は ま や ら わ`) plus `#`.
  ///
  /// Hiragana and katakana are supported (voiced and small kana fold into
  /// their row). Kanji cannot be bucketed without a reading, so kanji-only
  /// text goes to `#`; sort by a reading field and pass that to the grouper
  /// instead of the display name.
  factory AzIndexResolver.japanese() => AzIndexResolver(
        labels: <String>[...'あかさたなはまやらわ'.split(''), '#'],
        runeMapper: (int r) {
          int c = r;
          if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60; // katakana -> hiragana
          if (c < 0x3041 || c > 0x3093) return null;
          return _kanaRows[String.fromCharCode(c)];
        },
      );

  /// The ordered labels shown in the bar.
  final List<String> labels;

  /// Label for text that matches no other label (digits, symbols, other
  /// scripts, empty text).
  final String fallbackLabel;

  /// Whether Latin diacritics are folded before matching (`É` -> `E`).
  final bool foldDiacritics;

  /// Upper-case letters that keep their own bucket even when
  /// [foldDiacritics] is on, for example `{'Å', 'Ä', 'Ö'}`.
  final Set<String> preserve;

  /// Optional hook mapping the first code point to a label; see the
  /// constructor.
  final String? Function(int rune)? runeMapper;

  /// Returns the label that [text] belongs to.
  String resolve(String text) {
    final int? rune = _firstRune(text);
    if (rune == null) return fallbackLabel;
    final String? mapped = runeMapper?.call(rune);
    if (mapped != null && labels.contains(mapped)) return mapped;
    final String upper = String.fromCharCode(rune).toUpperCase();
    if (preserve.contains(upper) && labels.contains(upper)) return upper;
    if (foldDiacritics) {
      final String folded = _foldChar(upper);
      if (labels.contains(folded)) return folded;
    }
    if (labels.contains(upper)) return upper;
    return fallbackLabel;
  }

  /// Sort key: folded (when [foldDiacritics]) and lower-cased text, so that
  /// `Ärzte` sorts next to `Arzt`, not after `Z`.
  String sortKey(String text) {
    final String t = text.trim().toLowerCase();
    return foldDiacritics ? _foldKeep(t) : t;
  }

  /// Compares two strings using [sortKey], breaking ties on the raw text.
  int compare(String a, String b) {
    final int c = sortKey(a).compareTo(sortKey(b));
    return c != 0 ? c : a.compareTo(b);
  }

  String _foldKeep(String t) {
    if (preserve.isEmpty) return fold_(t);
    final StringBuffer b = StringBuffer();
    for (final String ch in t.split('')) {
      b.write(preserve.contains(ch.toUpperCase()) ? ch : fold_(ch));
    }
    return b.toString();
  }

  static String fold_(String s) => folding.foldDiacritics(s);

  static String _foldChar(String ch) {
    final String f = folding.foldDiacritics(ch).toUpperCase();
    return f.isEmpty ? ch : f.substring(0, 1);
  }

  static int? _firstRune(String text) {
    for (final int r in text.runes) {
      // skip whitespace and invisible marks
      final bool blank =
          r == 0x20 || r == 0x09 || r == 0x0A || r == 0xA0 || r == 0x200B;
      if (blank) {
        continue;
      }
      return r;
    }
    return null;
  }
}

final Map<String, String> _kanaRows = _buildKanaRows();

Map<String, String> _buildKanaRows() {
  const Map<String, String> rows = <String, String>{
    'あ': 'ぁあぃいぅうぇえぉおゔ',
    'か': 'かがきぎくぐけげこごゕゖ',
    'さ': 'さざしじすずせぜそぞ',
    'た': 'ただちぢっつづてでとど',
    'な': 'なにぬねの',
    'は': 'はばぱひびぴふぶぷへべぺほぼぽ',
    'ま': 'まみむめも',
    'や': 'ゃやゅゆょよ',
    'ら': 'らりるれろ',
    'わ': 'ゎわゐゑをん',
  };
  final Map<String, String> m = <String, String>{};
  for (final MapEntry<String, String> e in rows.entries) {
    for (final String ch in e.value.split('')) {
      m[ch] = e.key;
    }
  }
  return m;
}
