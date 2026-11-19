## 0.0.2

- Keeps the full pub.dev static analysis score on Flutter 3.50 and later, which deprecates `package:flutter/material.dart`. No API or behavior changes.

## 0.0.1

- Initial release.
- `AzIndexBar`: drag/tap scrubber with floating bubble, haptics hook, current-section highlight, disabled letters, compact mode, RTL, semantics, theming.
- `AzIndexResolver` / `AzGroups`: locale-aware grouping (diacritics folding, `#` bucket, Cyrillic, Greek, Devanagari, Korean, Japanese and custom indexes).
- `AzSectionScroller` and metrics: jump a plain `ScrollController` to a section (fixed, explicit or measured extents), no extra dependency.
- `AzSectionedListView`: ready-made list with sticky headers and the bar.
