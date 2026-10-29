import 'package:az_index_bar/az_index_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldDiacritics', () {
    test('folds accents, ligatures and combining marks', () {
      expect(foldDiacritics('Éclair Östen Ñandú'), 'Eclair Osten Nandu');
      expect(foldDiacritics('Straße Æsir Œuvre Łódź'),
          'Strasse AEsir OEuvre Lodz');
      expect(foldDiacritics('é'), 'e');
      expect(foldDiacritics('plain ascii 123'), 'plain ascii 123');
    });
  });

  group('AzIndexResolver.latin', () {
    final AzIndexResolver r = AzIndexResolver.latin();

    test('labels are A-Z then #', () {
      expect(r.labels.length, 27);
      expect(r.labels.first, 'A');
      expect(r.labels.last, '#');
    });

    test('hashFirst puts # before A', () {
      expect(AzIndexResolver.latin(hashFirst: true).labels.first, '#');
    });

    test('diacritics are folded into the base letter', () {
      expect(r.resolve('Émile'), 'E');
      expect(r.resolve('Östen'), 'O');
      expect(r.resolve('ñandú'), 'N');
      expect(r.resolve('ßeta'), 'S');
      expect(r.resolve('İbrahim'), 'I');
    });

    test('digits, symbols, empty and other scripts go to #', () {
      expect(r.resolve('42 Club'), '#');
      expect(r.resolve('_hidden'), '#');
      expect(r.resolve(''), '#');
      expect(r.resolve('   '), '#');
      expect(r.resolve('日本'), '#');
    });

    test('leading whitespace is ignored and case does not matter', () {
      expect(r.resolve('  anna'), 'A');
      expect(r.resolve('zoë'), 'Z');
    });

    test('preserve keeps Swedish letters in their own bucket', () {
      final AzIndexResolver sv = AzIndexResolver.latin(
        preserve: <String>{'Å', 'Ä', 'Ö'},
        extraLabels: <String>['Å', 'Ä', 'Ö'],
      );
      expect(sv.resolve('Åsa'), 'Å');
      expect(sv.resolve('Östen'), 'Ö');
      expect(sv.resolve('Éva'), 'E');
      // sorting keeps them apart from A / O too
      expect(sv.compare('Ola', 'Östen') < 0, isTrue);
      expect(sv.compare('Zed', 'Åsa') < 0, isTrue);
    });

    test('sorting folds accents so Ärzte sits next to Arzt', () {
      final List<String> names = <String>['Zoe', 'Ärzte', 'Arzt', 'Beta'];
      names.sort(r.compare);
      expect(names, <String>['Arzt', 'Ärzte', 'Beta', 'Zoe']);
    });
  });

  group('non-Latin presets', () {
    test('cyrillic', () {
      final AzIndexResolver r = AzIndexResolver.cyrillic();
      expect(r.resolve('Анна'), 'А');
      expect(r.resolve('ёлка'), 'Е');
      expect(r.resolve('Йоги'), 'И');
      expect(r.resolve('Zed'), '#');
    });

    test('greek folds accents', () {
      final AzIndexResolver r = AzIndexResolver.greek();
      expect(r.resolve('Άννα'), 'Α');
      expect(r.resolve('Ωραία'), 'Ω');
    });

    test('devanagari handles vowels, consonants and nukta', () {
      final AzIndexResolver r = AzIndexResolver.devanagari();
      expect(r.resolve('अनिल'), 'अ');
      expect(r.resolve('कमल'), 'क');
      expect(r.resolve('क़बर'), 'क'); // क़ precomposed
      expect(r.resolve('हरि'), 'ह');
      expect(r.resolve('Anil'), '#');
    });

    test('korean uses the initial consonant', () {
      final AzIndexResolver r = AzIndexResolver.korean();
      expect(r.resolve('김민수'), 'ㄱ');
      expect(r.resolve('까치'), 'ㄱ');
      expect(r.resolve('하늘'), 'ㅎ');
    });

    test('japanese buckets kana by row, katakana too', () {
      final AzIndexResolver r = AzIndexResolver.japanese();
      expect(r.resolve('あおい'), 'あ');
      expect(r.resolve('がく'), 'か');
      expect(r.resolve('サクラ'), 'さ');
      expect(r.resolve('ぱん'), 'は');
      expect(r.resolve('山田'), '#');
    });

    test('custom resolver with a runeMapper', () {
      final AzIndexResolver r = AzIndexResolver(
        labels: const <String>['1-3', '4-9', '#'],
        runeMapper: (int rune) {
          if (rune >= 0x31 && rune <= 0x33) return '1-3';
          if (rune >= 0x34 && rune <= 0x39) return '4-9';
          return null;
        },
      );
      expect(r.resolve('2 Fast'), '1-3');
      expect(r.resolve('7 Up'), '4-9');
      expect(r.resolve('Zed'), '#');
    });
  });

  group('AzGroups', () {
    final List<String> names = <String>[
      'Bea',
      'anna',
      'Émile',
      'Zoë',
      '42 Club',
      'Adam',
      'Eve',
      'bob',
    ];
    final AzGroups<String> g =
        AzGroups<String>.from(names, textOf: (String s) => s);

    test('sections are ordered, sorted and non-empty only', () {
      expect(g.sections.map((AzSection<String> s) => s.label),
          <String>['A', 'B', 'E', 'Z', '#']);
      expect(g.sections[0].items, <String>['Adam', 'anna']);
      expect(g.sections[2].items, <String>['Émile', 'Eve']);
      expect(g.itemCount, 8);
      expect(g.itemCounts, <int>[2, 2, 2, 1, 1]);
    });

    test('labels keep empty letters, enabledLabels does not', () {
      expect(g.labels.length, 27);
      expect(g.enabledLabels, <String>{'A', 'B', 'E', 'Z', '#'});
    });

    test('section lookup helpers', () {
      expect(g.sectionIndexOfLabel('E'), 2);
      expect(g.sectionIndexOfLabel('C'), -1);
      expect(g.nearestSectionIndexOfLabel('C'), 2); // next is E
      expect(g.nearestSectionIndexOfLabel('Y'), 3); // Z
      expect(g.nearestSectionIndexOfLabel('#'), 4);
    });

    test('flat indexes include headers by default', () {
      expect(g.flatIndexOfSection(0), 0);
      expect(g.flatIndexOfSection(1), 3);
      expect(g.flatIndexOfLabel('E'), 6);
      expect(g.flatIndexOfLabel('E', withHeaders: false), 4);
      expect(g.flatIndexOfLabel('C'), -1);
      expect(g.sectionIndexOfFlatIndex(0), 0);
      expect(g.sectionIndexOfFlatIndex(2), 0);
      expect(g.sectionIndexOfFlatIndex(3), 1);
      expect(g.sectionIndexOfFlatIndex(999), 4);
    });

    test('flatten yields header then items', () {
      final List<AzEntry<String>> flat = g.flatten();
      expect(flat.length, 8 + 5);
      expect(flat[0].isHeader, isTrue);
      expect(flat[0].label, 'A');
      expect(flat[1].item, 'Adam');
      expect(g.flatten(withHeaders: false).length, 8);
    });

    test('sort: false keeps input order, compare overrides', () {
      final AzGroups<String> keep = AzGroups<String>.from(
        <String>['Ben', 'Amy', 'Al'],
        textOf: (String s) => s,
        sort: false,
      );
      expect(keep.sections[0].items, <String>['Amy', 'Al']);
      final AzGroups<String> rev = AzGroups<String>.from(
        <String>['Ben', 'Amy', 'Al'],
        textOf: (String s) => s,
        compare: (String a, String b) => b.compareTo(a),
      );
      expect(rev.sections[0].items, <String>['Amy', 'Al']);
    });

    test('empty input gives no sections', () {
      final AzGroups<String> e =
          AzGroups<String>.from(<String>[], textOf: (String s) => s);
      expect(e.sections, isEmpty);
      expect(e.nearestSectionIndexOfLabel('A'), -1);
      expect(e.sectionIndexOfFlatIndex(0), -1);
    });
  });
}
