# az_index_bar

[![pub version](https://img.shields.io/pub/v/az_index_bar.svg)](https://pub.dev/packages/az_index_bar)
[![pub points](https://img.shields.io/pub/points/az_index_bar)](https://pub.dev/packages/az_index_bar/score)
[![likes](https://img.shields.io/pub/likes/az_index_bar)](https://pub.dev/packages/az_index_bar)
[![popularity](https://img.shields.io/pub/popularity/az_index_bar)](https://pub.dev/packages/az_index_bar/score)
[![CI](https://github.com/Rishav1995-roy/az_index_bar/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Rishav1995-roy/az_index_bar/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platforms](https://img.shields.io/badge/platforms-android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-informational)

An A-Z (or any custom) index scrubber for contact-style lists: drag or tap the bar, a bubble follows your finger, the list jumps, sticky headers stay pinned, empty letters are greyed out. Locale-aware grouping (accents, `#`, Cyrillic, Greek, Devanagari, Korean, Japanese), compact mode, RTL, accessibility and full theming. Pure Dart/Flutter with **no dependency besides Flutter**; it jumps a normal `ScrollController`.

![Demo](https://raw.githubusercontent.com/Rishav1995-roy/az_index_bar/main/doc/demo.gif)

<p>
  <img src="https://raw.githubusercontent.com/Rishav1995-roy/az_index_bar/main/doc/screenshot_light.png" width="260" alt="Light theme">
  <img src="https://raw.githubusercontent.com/Rishav1995-roy/az_index_bar/main/doc/screenshot_dark.png" width="260" alt="Dark theme with custom bar style">
</p>

> The GIF and screenshots are rendered by a Flutter test from the real example UI (see `tool/demo`), not recorded on a device.

## Why this package

[`azlistview`](https://pub.dev/packages/azlistview) (last release 2022-02) is the best-known option, and it relies on `scrollable_positioned_list`, which is archived. This package keeps the same idea and fixes the problems people reported:

| Problem | `azlistview` | `az_index_bar` |
|---|---|---|
| Depends on archived `scrollable_positioned_list` ([#75](https://github.com/flutterchina/azlistview/issues/75), [#92](https://github.com/flutterchina/azlistview/issues/92)) | Yes | **No.** Only Flutter. Jumps a plain `ScrollController` (fixed, explicit or measured heights) |
| Bubble sometimes does not disappear after releasing ([#101](https://github.com/flutterchina/azlistview/issues/101)) | Reported | Raw pointer handling; release, cancel, second finger and dispose are all covered by tests |
| Haptics ([#104](https://github.com/flutterchina/azlistview/issues/104), [#95](https://github.com/flutterchina/azlistview/issues/95)) | Reported as poor / missing | One tick per label crossed, `onHaptic` hook, can be turned off |
| Short lists, tiny item counts ([#100](https://github.com/flutterchina/azlistview/issues/100)) | Position wrong | The section you tapped stays current even when the list cannot scroll that far |
| Tall label size makes the bar unclickable ([#73](https://github.com/flutterchina/azlistview/issues/73)), small screens ([#88](https://github.com/flutterchina/azlistview/issues/88)) | Reported | Hit areas follow the real layout; the bar collapses into dots when it does not fit (compact mode) |
| Bar always centred / limited styling ([#77](https://github.com/flutterchina/azlistview/issues/77), [#76](https://github.com/flutterchina/azlistview/issues/76), [#94](https://github.com/flutterchina/azlistview/issues/94)) | Limited | `AzIndexBarThemeData`: colours, text styles, shapes, sizes, `barPadding`, bubble builder |
| Non-Latin or accented names | Bring your own tag | Built-in resolvers and diacritics folding |
| Maintained, null-safe, current Flutter | Last release 2022 | Tested on Flutter 3.27 and the latest stable |

Other packages in this space ([`alphabet_list_scroll_view`](https://pub.dev/packages/alphabet_list_scroll_view) 2021, [`sticky_az_list`](https://pub.dev/packages/sticky_az_list) 2023, [`alphabet_index_listview`](https://pub.dev/packages/alphabet_index_listview)) are fine for simple cases; this one aims to be the maintained, dependency-free, fully themeable choice. Use whichever fits your list.

## Features

- Drag and tap scrubbing, floating bubble that follows the finger, custom bubble builder
- Haptic hook, one tick per label change
- Highlight of the section currently at the top of the list
- Disabled letters for empty sections, with three behaviours when touched (`ignore`, `snapToNext`, `snapToNearest`)
- Locale-aware grouping and sorting: diacritics folding (`É` -> `E`, `Ö` -> `O`), `#` bucket for digits and symbols, `preserve` for letters that are real letters (`Å Ä Ö`), presets for Cyrillic, Greek, Devanagari, Korean (initial consonant), Japanese (kana rows), and custom indexes through a `runeMapper`
- Compact mode: when the labels do not fit, the bar shows every n-th label with dots between (iOS style); dots select the label in the middle of the ones they hide
- Sticky section headers (`AzSectionedListView`)
- RTL: bar and bubble flip with `Directionality`
- Accessibility: the bar is one slider-like node (`increase` / `decrease` step through enabled labels, value is the current label)
- Section offsets for a plain `ScrollController`: fixed-height, explicit per-section heights, or measured from the laid-out slivers
- Works with any list through the generic `onIndexSelected` callback

## Platform support

| Android | iOS | Web | macOS | Windows | Linux |
|---|---|---|---|---|---|
| Yes | Yes | Yes (incl. WASM) | Yes | Yes | Yes |

Pure Dart and Flutter, no native code. Haptics use `HapticFeedback` (a no-op where unsupported).

## Install

```sh
flutter pub add az_index_bar
```

## Quick start

```dart
final groups = AzGroups<String>.from(names, textOf: (n) => n);

AzSectionedListView<String>(
  groups: groups,
  itemExtent: 64, // optional: exact jumps when every item has the same height
  headerBuilder: (context, section, i) => Text(section.label),
  itemBuilder: (context, name, sectionIndex, indexInSection) =>
      ListTile(title: Text(name)),
)
```

That is a complete contact list: sticky headers, the bar on the end side, bubble, haptics, highlight and empty letters greyed out. Leave `itemExtent` out for items of any height; offsets are then measured and refined for a few frames after a jump.

### Use the bar with your own list

`AzIndexBar` knows nothing about lists; it reports the label under the finger.

**Plain `ScrollController`** (no extra package):

```dart
final controller = ScrollController();
final scroller = AzSectionScroller(
  controller: controller,
  metrics: AzFixedSectionMetrics(
    itemCounts: groups.itemCounts,
    headerExtent: 28,
    itemExtent: 48,
  ),
);

// in build:
Stack(children: [
  ListView.builder(controller: controller, /* flat list with headers */),
  PositionedDirectional(
    end: 0, top: 0, bottom: 0,
    child: ValueListenableBuilder<int>(
      valueListenable: scroller.currentSection,
      builder: (context, current, _) => AzIndexBar(
        labels: groups.labels,
        enabledLabels: groups.enabledLabels,
        currentLabel: groups.sections[current].label,
        onIndexSelected: (index, label) =>
            scroller.jumpToSection(groups.sectionIndexOfLabel(label)),
      ),
    ),
  ),
]);
```

If you know every section's height use `AzExtentSectionMetrics(extents)`; or implement `AzSectionMetrics` yourself. Dispose the scroller in `State.dispose`.

**`scrollable_positioned_list` or any indexed list** (not a dependency; just an example):

```dart
AzIndexBar(
  labels: groups.labels,
  enabledLabels: groups.enabledLabels,
  onIndexSelected: (index, label) => itemScrollController.jumpTo(
    index: groups.flatIndexOfLabel(label), // header rows included
  ),
);
```

`groups.flatten()` gives the matching list of header and item entries.

### Grouping and alphabets

```dart
AzGroups<String>.from(names, textOf: (n) => n);                                // A-Z + #
AzGroups<String>.from(names, textOf: (n) => n,
    resolver: AzIndexResolver.cyrillic());                                      // А-Я + #
AzGroups<Person>.from(people, textOf: (p) => p.name,
    resolver: AzIndexResolver.latin(
      preserve: {'Å', 'Ä', 'Ö'}, extraLabels: ['Å', 'Ä', 'Ö'])); // Swedish

// Any index: map the first character to a label.
AzIndexResolver(
  labels: const ['1-3', '4-9', '#'],
  runeMapper: (rune) => rune >= 0x31 && rune <= 0x33 ? '1-3' : (rune <= 0x39 && rune >= 0x34 ? '4-9' : null),
);
```

Presets: `latin`, `cyrillic`, `greek`, `devanagari`, `korean`, `japanese`. Kanji cannot be bucketed without a reading: pass the reading (kana) as `textOf` and show the kanji in your item.

## API

### `AzIndexBar`

| Parameter | Description |
|---|---|
| `labels` (required) | Labels top to bottom |
| `onIndexSelected(index, label)` (required) | Called on touch down and whenever the label under the finger changes |
| `enabledLabels` | Labels with content; others are drawn disabled. Null enables all |
| `currentLabel` | Highlighted when not touching (usually the top section) |
| `disabledBehavior` | `ignore`, `snapToNext` (default), `snapToNearest` |
| `hapticFeedback` / `onHaptic` | Toggle / replace the default `HapticFeedback.selectionClick` |
| `showBubble` / `bubbleBuilder` | Toggle / replace the bubble widget |
| `onSelectionStart` / `onSelectionEnd` | Paired touch callbacks (also fire on cancel and dispose) |
| `theme` | `AzIndexBarThemeData`, merged over an ambient `AzIndexBarTheme` |
| `semanticLabel` | Accessibility label (default `Section index`) |

### `AzIndexBarThemeData`

`width`, `minLabelExtent` (below this the bar goes compact), `maxLabelExtent`, `padding`, `backgroundColor`, `activeBackgroundColor`, `borderRadius`, `labelStyle`, `activeLabelStyle`, `disabledLabelStyle`, `dotColor`, `dotSize`, `bubbleSize`, `bubbleColor`, `bubbleShape`, `bubbleTextStyle`, `bubbleGap`, `activeShape`. Everything defaults from the ambient `ThemeData`. Provide it per bar, or for a subtree with `AzIndexBarTheme`.

### `AzSectionedListView<T>`

`groups`, `itemBuilder`, `headerBuilder`, `headerExtent`, `itemExtent`, `estimatedItemExtent`, `stickyHeaders`, `controller` (`AzSectionedListController`: `scrollController`, `currentSection`, `jumpToSection`, `animateToSection`), `physics`, `topPadding`, `bottomPadding`, `showIndexBar`, `reserveBarSpace`, `barPadding`, `barTheme`, the bar options above, `animateJumps`, `onSectionChanged`.

### Grouping, metrics

| Type | Purpose |
|---|---|
| `AzIndexResolver` | label for a string + sort order; presets and custom |
| `AzGroups<T>` | sections, `labels`, `enabledLabels`, `flatIndexOfLabel`, `flatten()` |
| `AzSectionScroller` | jump / animate a `ScrollController`, `currentSection` |
| `AzFixedSectionMetrics`, `AzExtentSectionMetrics`, `AzSectionMetrics` | section offsets |
| `computeBarSlots` | the pure compact-mode layout function |
| `foldDiacritics` | the folding used by the resolvers |

## Coming from `azlistview`

| `azlistview` | `az_index_bar` |
|---|---|
| items extend `ISuspensionBean` with `tagIndex` | any type; `AzGroups.from(items, textOf: ...)` computes sections and sorts |
| `SuspensionUtil.sortListBySuspensionTag` / `setShowSuspensionStatus` | done by `AzGroups.from` |
| `AzListView(data, itemBuilder, susItemBuilder, indexBarOptions)` | `AzSectionedListView(groups, itemBuilder, headerBuilder, barTheme)` |
| `IndexBarOptions` | `AzIndexBarThemeData` + a few `AzIndexBar` parameters |
| `ItemScrollController` from `scrollable_positioned_list` | plain `ScrollController` / `AzSectionedListController`; or keep your list and use `onIndexSelected` |

## FAQ

**Items have different heights, are jumps exact?** Without `itemExtent`, the section offset is read from the laid-out slivers and corrected for up to six frames after the jump, so the header lands at the top; the first jump to a far section may visibly correct itself. With `itemExtent` or `AzExtentSectionMetrics` it is exact in one jump.

**The last letters do not reach the top.** A list cannot scroll past its end. The section you picked is still reported as current (and highlighted) until you scroll away.

**Can the bar be horizontal?** Not in 0.0.1.

**Do I need `AzSectionedListView`?** No. `AzIndexBar` plus `AzGroups` (and optionally `AzSectionScroller`) work with any list.

## Contributing

Issues and pull requests are welcome at [github.com/Rishav1995-roy/az_index_bar](https://github.com/Rishav1995-roy/az_index_bar). Run `flutter analyze` and `flutter test` before opening a PR. The demo GIF is regenerated with `flutter test tool/demo/generate_demo_test.dart && tool/make_gif.sh`.

## License

MIT, see [LICENSE](LICENSE).
