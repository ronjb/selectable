# CLAUDE.md

## Project Overview

Flutter package called `selectable` that enables text selection over all text widgets it contains. It predates Flutter's native `SelectableRegion` but continues to be maintained for existing projects.

## Development Commands

```bash
flutter test                              # Run all tests
flutter test test/specific_test.dart      # Run specific test file
flutter analyze                           # Static analysis
cd example && flutter run                 # Run example app
```

## Key Dependencies

- `float_column`: Complex text layout (major dependency)
- `characters`: Unicode-aware string manipulation
- `collection`: Collection utilities
- `url_launcher`: Web search in selection menu
- `equatable`: Object equality comparisons

## Architecture Notes

- `Selectable` widget wraps content to enable text selection (`lib/src/selectable.dart`)
- `SelectableController` manages selection state (`lib/src/selectable_controller.dart`)
- Platform-specific controls in `lib/src/material/` and `lib/src/cupertino/`
- Uses `float_column` for text layout rendering
