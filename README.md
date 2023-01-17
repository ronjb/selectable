# selectable

[![Pub](https://img.shields.io/pub/v/selectable.svg)](https://pub.dev/packages/selectable)

A Flutter widget that enables text selection over all the text widgets it contains.

Try it out at: [https://ronjb.github.io/selectable](https://ronjb.github.io/selectable)

## ⭐️ **IMPORTANT** ⭐️

This library was written over a year before [`SelectableRegion`](https://api.flutter.dev/flutter/widgets/SelectableRegion-class.html) and related classes were added to Flutter. I will continue to maintain this library because I still use it in a few of my projects, but now that Flutter natively supports selection, I'd recommend using their implementation if it meets your needs.

## Getting Started

Add this to your app's `pubspec.yaml` file:

```yaml
dependencies:
  selectable: ^0.2.11
```

## Usage

Then in the dart file, import the package with:

```dart
import 'package:selectable/selectable.dart';
```

And use `Selectable` where appropriate. For example:

```dart
Scaffold(
  body: SingleChildScrollView(
    child: Selectable(
      child: Column(
        children: [
          Text('... a lot of text ...'),
          // ... more widgets of any type that might contain text ...
        ],
      )
    )
  )
)
```

**Important Note**: As shown in the example above, if a scrollable widget (such as `SingleChildScrollView`, `ListView`, `CustomScrollView`, etc.) is used to wrap the text widgets you want to enable selection for, the `Selectable` widget must be a descendant of the scrollable widget, and an ancestor of the text widgets.

`Selectable` by default supports long-pressing on a word to select it, then using the selection handles to adjust the selection. To also enable double-tapping on a word to select it, pass in `selectWordOnDoubleTap: true` like this:

```dart
Selectable(
  selectWordOnDoubleTap: true,
  child: child,
)
```

## Wrap widgets that shouldn't be selectable in `IgnoreSelectable`

For example:

```dart
IgnoreSelectable(
  child: Text(
    'This text is wrapped in an IgnoreSelectable widget, so it is not selectable.',
    style: textStyle2,
  ),
),

```

## Customizable Popup Selection Menu

`Selectable` provides a default popup selection menu with the menu items Copy, Define, and WebSearch, but it can easily be customized. For example, to continue to show the default Copy menu item, and to add a custom menu item with the title "Foo! :)", which shows the selected text in an AlertDialog, do this:

```dart
Selectable(
  child: child,
  popupMenuItems: [
    SelectableMenuItem(type: SelectableMenuItemType.copy),
    SelectableMenuItem(
      title: 'Foo! :)',
      isEnabled: (controller) => controller!.isTextSelected;
      handler: (controller) {
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (builder) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: Container(
                padding: const EdgeInsets.all(16),
                child: Text(controller!.getSelection()!.text!),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            );
          },
        );
        return true;
      },
    ),
  ],
)
```

## Add an Issue for Questions or Problems

Look at the code in the example app included with this package for more usage details and example code, and feel free to add an issue to ask questions or report problems you find while using this package: [https://github.com/ronjb/selectable/issues](https://github.com/ronjb/selectable/issues)
