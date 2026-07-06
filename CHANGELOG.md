# CHANGELOG

## [0.6.5] - July 6, 2026

* Fixed a listener leak where the scroll listener was removed from the scroll controller's current `ScrollPosition` instead of the one it was added to, which leaked the listener if the controller gained clients or swapped positions.
* Fixed stale selections: removing trailing paragraphs (or all paragraphs) now updates the paragraph cache version, so selections referencing text that no longer exists are cleared.
* Fixed `IgnoreSelectable` so toggling `ignoring` at runtime updates the contained text immediately, without requiring an unrelated relayout.
* Fixed an endless rebuild loop that occurred when a custom rectifier returned an empty rect list.
* Fixed `SelectableController.hide(duration:)` and `unhide(duration:)` so the painted highlight animates with the provided duration (previously it always animated for one second).
* Improved word selection around punctuation and whitespace: selecting at the first letter of a word preceded by a quote, punctuation, or multiple spaces now selects the word (previously nothing, or the punctuation, was selected), and selecting at the end of a wrapped line no longer includes the trailing space.
* Fixed iOS popup menu placement: the top screen inset (e.g. the notch) no longer counts against the space below the selection, so the menu is placed just below the selection instead of jumping to the center of the viewport; also, the menu arrow position is now clamped in local coordinates, so the arrow stays attached to the menu when the Selectable doesn't span the full screen width.
* Fixed the Material popup menu so, when placed below the selection, it keeps the minimum 8px padding from the bottom of the viewport.
* Fixed the experimental popup menu (`useExperimentalPopupMenu: true`) anchors on both platforms, so the menu is placed just above the selection, or just below it when there is no room above.
* Fixed the Cupertino popup menu so its buttons shrink and ellipsize to fit a narrow viewport instead of overflowing (matching the Material fix in 0.6.2).
* Fixed the Material popup menu so a long menu-item title is no longer needlessly ellipsized when the menu fits the viewport — buttons now only shrink (proportionally to their content) when the menu would otherwise overflow.
* Fixed the Material popup menu buttons to use the ambient app theme (previously ink effects and fonts came from a default light theme, even in dark mode).
* The default menu item titles are now localized using `MaterialLocalizations` (falling back to `CupertinoLocalizations`). Note, in English, 'Define' is now 'Look Up' and 'WebSearch' is now 'Search Web'. Also, `SelectableMenuItem.title` is now null for the built-in types unless explicitly provided — custom menu builders can use the new `defaultTitleForMenuItemType` function to resolve default titles.
* Fixed 'Look Up' and 'Search Web' silently doing nothing on Android 11+ in apps without a `<queries>` manifest entry, by calling `launchUrl` directly instead of gating on `canLaunchUrl`.
* The 'Look Up' (define) menu item is now correctly disabled for selections of more than two words separated by any whitespace (e.g. newlines), not just spaces.
* Hardened lifecycle and release-mode edge cases: menu items missing `isEnabled` or `handler` no longer crash release builds, and post-frame and gesture callbacks now guard against unmounted state.
* Fixed the start selection point to be text-direction aware when anchors are refreshed after a layout change (RTL).
* Performance: dragging a selection handle now computes the selection once per drag update instead of once per selection access, roughly a 4x reduction in work per drag frame.
* Performance: the paragraph cache is now updated lazily on first access instead of on every layout, so layouts with no active selection (e.g. scrolling or keyboard animations) skip the full render-tree walk entirely.
* Performance: cheaper per-frame selection equality checks, and the iOS popup menu's clip path is now cached at layout time and its clip layer reused, instead of being recomputed on every paint.

## [0.6.4] - June 19, 2026

* Added the `containedTextLength` getter to `SelectableController`, which returns the number of characters (UTF-16 code units) in the combined text of all contained paragraphs without allocating the combined string. The result is memoized against the paragraph cache version, so repeated reads between content changes are O(1).

## [0.6.3] - June 6, 2026

* Fixed the Cupertino (iOS-style) text selection popup menu so Japanese (and other tall) text labels are not clipped vertically. Thanks to @madoka3530 for the fix (#29).

## [0.6.2] - June 4, 2026

* Fixed the Material text selection popup menu so a long menu-item title (or too many items to fit) shrinks and ellipsizes within the viewport instead of throwing a `RenderFlex` overflow error (#6, #17).

## [0.6.1] - June 4, 2026

* Fixed the Material text selection popup menu so Japanese (and other tall) text labels are not clipped vertically. Thanks to @madoka3530 for the fix (#28).

## [0.6.0] - June 4, 2026

* Raised the minimum SDK constraints to Dart 3.10.0 and Flutter 3.28.0.
* Extracted `SelectableControllerBase` abstract base class from `SelectableController`, enabling alternative controller implementations.
* Added comprehensive unit tests for the controller API.
* Fixed the Cupertino text selection popup menu so its buttons render flush (no rounded corners) by passing `BorderRadius.zero` instead of `null` to `CupertinoButton.borderRadius`. Thanks to @madoka3530 for the fix (#27).

## [0.5.2] - August 11, 2025

* Added try/catch in SelectionParagraph visitChildSpans to catch rare cases where the RenderParagraph's text property might throw an exception because it returns `_textPainter.text!` and the `.text` can be null.

## [0.5.1] - July 31, 2025

* Removed deprecated and unused code and some code cleanup.

## [0.5.0] - March 10, 2025

* Updated to use the latest version of the float_column library which has new rendering code for better compatibility with a wider range of Flutter versions.

## [0.4.0] - February 12, 2025

* Breaking change: Flutter 3.29.0 required breaking change to the float_column package that this library depends on.

## [0.3.3] - October 23, 2024

* Started adding support for right-to-left languages, still a work in progress.

## [0.3.2] - August 12, 2024

* Updated to use latest float_column version that supports Flutter 3.24.0.

## [0.3.1] - February 21, 2024

* Updated to use latest float_column version with build fixes for Flutter 3.19.0.
* Added optional `bool useExperimentalPopupMenu = false` parameter to the Selectable class.

## [0.3.0] - May 1, 2023

* Updated to support Dart 3 and Flutter 3.10.0.

## [0.2.11] - January 17, 2023

* Updated the `TaggedTextSpan` class's `splitAtIndex` method to use the new `copyWithTextSpan` parameter of `defaultSplitSpanAtIndex` to call the correct `copyWith` method, depending on the type.

## [0.2.10] - January 17, 2023

* Updated to use latest float_column version with bug fix.

## [0.2.9] - December 30, 2022

* Removed from SelectableController the deprecated properties `text`, `selectionStart`, `selectionEnd`, and `rects`.
* Added the ability to customize how the rectangles of selected text is converted to selection rectangles via the new SelectableController `setCustomRectifier` method. See the included example app for an example of its use.
* Added `bool selectAll()` to the SelectableController class.

## [0.2.8] - December 10, 2022

* Added `int? get startIndex` and `int? get endIndex` to the Selection class.
* Added `final IconData? icon` to the SelectableMenuItem class.
* Updated the example app to show how to interact with the underlying text spans, for example, updating selected text spans to a different color.

## [0.2.7] - October 30, 2022

* Deprecated `isWhitespaceRune` and added `isWhitespaceCharacter` and `isNonWordCharacter`.

## [0.2.6] - October 9, 2022

* Fixed Issue #7 "Crash when adjusting selection handles".

## [0.2.4] - June 28, 2022

* Added `IgnoreSelectable` widget for wrapping widgets that should not be selectable.

## [0.2.3] - June 4, 2022

* Fixed a bug where in some cases the selection wouldn't repaint in the correct location after a window resize.
* Updated so dragging a selection control with a finger places the point of contact above the finger.

## [0.2.2] - June 3, 2022

* README updates.

## [0.2.1] - June 3, 2022

* Some code cleanup, and update to the example app.

## [0.2.0] - June 1, 2022

* Bug fixes and new features.

## [0.1.3] - November 14, 2021

* Updated to create a SelectableController for use internally if one is not provided.

## [0.1.2] - October 12, 2021

* Added `bool selectWordOnLongPress` and `bool selectWordOnDoubleTap` to the Selectable constructor. To not break current usage, selectWordOnLongPress defaults to true, and selectWordOnDoubleTap defaults to false.
* Updated the src/material/text_selection.dart buildHandle function to set the handle color to `TextSelectionTheme.of(context).selectionHandleColor ?? theme.colorScheme.primary`, which fixes #2
* Updated the default selection color to be: `TextSelectionTheme.of(context).selectionColor ?? (_selection.usingCupertinoControls ? CupertinoTheme.of(context).primaryColor.withOpacity(0.25) : Theme.of(context).colorScheme.primary.withOpacity(0.25))`

## [0.1.1] - September 19, 2021

* Example app updates.

## [0.1.0] - September 16, 2021

* Initial release.
