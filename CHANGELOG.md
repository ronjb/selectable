# CHANGELOG

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
