# selectable

[![Pub](https://img.shields.io/pub/v/selectable.svg)](https://pub.dev/packages/selectable)

A Flutter widget that enables text selection over all the text widgets it
contains — with platform-adaptive selection handles and popup menu, a
controller for listening to and programmatically changing the selection, and
customizable menu items, selection color, and selection rendering.

Try it out at: [https://ronjb.github.io/selectable](https://ronjb.github.io/selectable)

> **Note:** This library predates Flutter's
> [`SelectableRegion`](https://api.flutter.dev/flutter/widgets/SelectableRegion-class.html)
> and related classes. It continues to be maintained because it is used in
> production apps, but if Flutter's native selection support meets your
> needs, consider using it instead.

## Features

* Selection across **all** the text widgets contained in a `Selectable` —
  multiple `Text` and `RichText` widgets, spanning paragraphs.
* Long-press (and optionally double-tap) a word to select it, then drag the
  selection handles to adjust the selection, with autoscroll when dragging
  near the top or bottom of a scrollable viewport.
* Platform-adaptive selection controls and popup menu: Cupertino style on
  iOS and macOS, Material style elsewhere.
* A default popup menu with Copy, Look Up, and Search Web items — localized
  using the ambient `MaterialLocalizations`/`CupertinoLocalizations` — and
  support for replacing or extending the menu with custom items.
* A `SelectableController` for listening to selection changes and for
  programmatically selecting, deselecting, hiding, and showing the
  selection.
* Customizable selection appearance via `selectionColor`, selection rect
  "rectifiers", and fully custom selection painters.
* `IgnoreSelectable` for excluding subtrees from selection.

## Getting started

Add `selectable` to your app's `pubspec.yaml` file:

```yaml
dependencies:
  selectable: ^0.6.5
```

Requires Dart `>=3.10.0` and Flutter `>=3.28.0`.

## Usage

Import the package:

```dart
import 'package:selectable/selectable.dart';
```

And wrap the widgets you want to enable text selection for in a
`Selectable`:

```dart
Scaffold(
  body: SingleChildScrollView(
    child: Selectable(
      child: Column(
        children: [
          Text('... a lot of text ...'),
          // ... more widgets of any type that might contain text ...
        ],
      ),
    ),
  ),
)
```

> **Important:** If a scrollable widget (such as `SingleChildScrollView`,
> `ListView`, or `CustomScrollView`) is used to wrap the text widgets you
> want to enable selection for, the `Selectable` widget must be a
> *descendant* of the scrollable widget and an *ancestor* of the text
> widgets.

### Scrollables and app bars

If the `Selectable` is in a scrollable, pass the scrollable's
`ScrollController` to the `Selectable` as well. It is used to autoscroll
when a selection handle is dragged near the top or bottom of the viewport,
and to keep the popup menu positioned in the visible area. If part of the
viewport is covered by an overlay, such as a pinned app bar, set
`topOverlayHeight` to its height:

```dart
Selectable(
  scrollController: _scrollController,
  topOverlayHeight: kToolbarHeight + MediaQuery.paddingOf(context).top,
  child: child,
)
```

### Selection gestures

Long-pressing a word selects it. To also enable double-tapping a word to
select it, set `selectWordOnDoubleTap` to true:

```dart
Selectable(
  selectWordOnDoubleTap: true,
  child: child,
)
```

### Excluding widgets from selection

Wrap widgets that shouldn't be selectable in `IgnoreSelectable`:

```dart
IgnoreSelectable(
  child: Text('This text is not selectable.'),
)
```

### Customizing the popup menu

`Selectable` shows a popup menu with Copy, Look Up, and Search Web items by
default. The default item titles are localized using the ambient
`MaterialLocalizations` (or `CupertinoLocalizations`). To customize the
menu, pass in `popupMenuItems`. For example, to show the default Copy item
along with a custom item that shows the selected text in a dialog:

```dart
Selectable(
  popupMenuItems: [
    const SelectableMenuItem(type: SelectableMenuItemType.copy),
    SelectableMenuItem(
      title: 'Show It',
      isEnabled: (controller) => controller!.isTextSelected,
      handler: (controller) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(controller!.getSelection()!.text!),
          ),
        );
        return true;
      },
    ),
  ],
  child: child,
)
```

Menu items can also have an `icon`, and custom menu builders can resolve
the localized default title for a built-in item type with
`defaultTitleForMenuItemType`.

### Using a SelectableController

Pass a `SelectableController` to the `Selectable` to listen to selection
changes and to work with the selection programmatically:

```dart
final _selectionController = SelectableController();

// In the widget tree:
Selectable(
  selectionController: _selectionController,
  child: child,
)

// Listen for selection changes.
_selectionController.addListener(() {
  if (_selectionController.isTextSelected) {
    print('Selected text: ${_selectionController.getSelection()!.text}');
  }
});
```

The controller supports, among other things:

```dart
// Select programmatically.
_selectionController.selectAll();
_selectionController.selectWordAtIndex(100);
_selectionController.selectWordsBetweenIndexes(100, 200);

// Deselect.
_selectionController.deselect();

// Hide and show the selection (e.g. while a dialog is showing),
// with an optional fade animation duration.
_selectionController.hide();
_selectionController.unhide();

// Get the combined text of all the text widgets contained in the
// Selectable (useful with the index-based select methods above), or
// just its length.
final text = _selectionController.getContainedText();
final length = _selectionController.containedTextLength;
```

The `Selection` object returned by `getSelection()` includes the selected
`text`, the global `startIndex` and `endIndex` of the selection, and the
selection rectangles. Remember to `dispose` the controller when it is no
longer needed.

### Customizing the selection appearance

The selection color can be set with the `selectionColor` parameter. How the
raw rectangles of selected text are converted into the displayed selection
rects can be customized with a "rectifier" — for example, to merge the
per-line rects into, at most, three contiguous rects:

```dart
_selectionController.setCustomRectifier(SelectionRectifiers.merged);
```

or provide your own `List<Rect> Function(List<Rect>)`. For full control
over how the selection is drawn, implement a custom `SelectionPainter` and
set it with `_selectionController.setCustomPainter` (see
`example/lib/my_selection_painter.dart`).

## Additional information

The [example app](https://github.com/ronjb/selectable/tree/main/example)
demonstrates most of these features, including advanced use cases such as
updating the style of the selected text spans.

Feel free to file an issue to ask questions or report problems:
[https://github.com/ronjb/selectable/issues](https://github.com/ronjb/selectable/issues)
