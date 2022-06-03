# CHANGELOG

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
