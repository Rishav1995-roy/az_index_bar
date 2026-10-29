/// Pure-Dart diacritics folding for Latin scripts.
///
/// Maps accented letters to their base letter (`é` -> `e`, `Ö` -> `O`) and
/// expands a few ligatures (`ß` -> `ss`, `Æ` -> `AE`). Combining marks
/// (U+0300 to U+036F) are dropped, so decomposed input behaves like
/// precomposed input.
String foldDiacritics(String input) {
  final StringBuffer out = StringBuffer();
  for (final int rune in input.runes) {
    if (rune < 0xC0) {
      out.writeCharCode(rune);
    } else if (rune >= 0x0300 && rune <= 0x036F) {
      continue;
    } else {
      final String? mapped = _table[rune];
      if (mapped != null) {
        out.write(mapped);
      } else {
        out.writeCharCode(rune);
      }
    }
  }
  return out.toString();
}

const Map<String, String> _upperGroups = <String, String>{
  'A': 'ÀÁÂÃÄÅĀĂĄǍǞǠǺȂȦ',
  'C': 'ÇĆĈĊČ',
  'D': 'ĎĐÐ',
  'E': 'ÈÉÊËĒĔĖĘĚȄȆȨ',
  'G': 'ĜĞĠĢǦǴ',
  'H': 'ĤĦ',
  'I': 'ÌÍÎÏĨĪĬĮİǏȈȊ',
  'J': 'Ĵ',
  'K': 'ĶǨ',
  'L': 'ĹĻĽĿŁ',
  'N': 'ÑŃŅŇǸ',
  'O': 'ÒÓÔÕÖØŌŎŐƠǑǪǬǾȌȎȪȬȮȰ',
  'R': 'ŔŖŘȐȒ',
  'S': 'ŚŜŞŠȘ',
  'T': 'ŢŤŦȚ',
  'U': 'ÙÚÛÜŨŪŬŮŰŲƯǓǕǗǙǛȔȖ',
  'W': 'Ŵ',
  'Y': 'ÝŶŸȲ',
  'Z': 'ŹŻŽ',
};

const Map<String, String> _lowerGroups = <String, String>{
  'a': 'àáâãäåāăąǎǟǡǻȃȧ',
  'c': 'çćĉċč',
  'd': 'ďđð',
  'e': 'èéêëēĕėęěȅȇȩ',
  'g': 'ĝğġģǧǵ',
  'h': 'ĥħ',
  'i': 'ìíîïĩīĭįıǐȉȋ',
  'j': 'ĵ',
  'k': 'ķǩ',
  'l': 'ĺļľŀł',
  'n': 'ñńņňŉǹ',
  'o': 'òóôõöøōŏőơǒǫǭǿȍȏȫȭȯȱ',
  'r': 'ŕŗřȑȓ',
  's': 'śŝşšș',
  't': 'ţťŧț',
  'u': 'ùúûüũūŭůűųưǔǖǘǚǜȕȗ',
  'w': 'ŵ',
  'y': 'ýÿŷȳ',
  'z': 'źżž',
};

final Map<int, String> _table = _buildTable();

Map<int, String> _buildTable() {
  final Map<int, String> t = <int, String>{
    0xDF: 'ss',
    0x1E9E: 'SS',
    0xC6: 'AE',
    0xE6: 'ae',
    0x152: 'OE',
    0x153: 'oe',
    0xDE: 'Th',
    0xFE: 'th',
  };
  for (final MapEntry<String, String> e in _upperGroups.entries) {
    for (final int r in e.value.runes) {
      t[r] = e.key;
    }
  }
  for (final MapEntry<String, String> e in _lowerGroups.entries) {
    for (final int r in e.value.runes) {
      t[r] = e.key;
    }
  }
  return t;
}
