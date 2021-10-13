# selectable

[![Pub](https://img.shields.io/pub/v/selectable.svg)](https://pub.dev/packages/selectable)

A Flutter widget that enables text selection over all the text widgets it contains.

Try it out at: [https://ronjb.github.io/selectable](https://ronjb.github.io/selectable)

## Getting Started

Add this to your app's `pubspec.yaml` file:

```yaml
dependencies:
  selectable: ^0.1.2
```

## Usage

Then you have to import the package with:

```dart
import 'package:selectable/selectable.dart';
```

And use `Selectable` where appropriate. For example:

```dart
Selectable(
    child: widgetWithTextWidgets,
    selectionColor: Colors.orange.withAlpha(75),
    showSelection: _showSelection,
    showPopup: true,
    popupMenuItems: _selectionMenuItems,
    selectionController: _selectionController,
    scrollController: _scrollController,
),
```
