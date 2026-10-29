/// A-Z index scrubber bar for contact-style lists: floating bubble, sticky
/// section headers, locale-aware grouping, disabled letters, compact mode,
/// RTL and accessibility, with no dependency besides Flutter.
library;

export 'src/bar_slots.dart' show AzBarSlot, computeBarSlots;
export 'src/folding.dart' show foldDiacritics;
export 'src/grouping.dart' show AzEntry, AzGroups, AzSection;
export 'src/index_bar.dart'
    show AzBubbleBuilder, AzDisabledBehavior, AzIndexBar;
export 'src/index_resolver.dart' show AzIndexResolver;
export 'src/section_metrics.dart'
    show
        AzExtentSectionMetrics,
        AzFixedSectionMetrics,
        AzSectionMetrics,
        AzSectionScroller;
export 'src/sectioned_list.dart'
    show
        AzHeaderBuilder,
        AzItemBuilder,
        AzSectionedListController,
        AzSectionedListView;
export 'src/theme.dart' show AzIndexBarTheme, AzIndexBarThemeData;
