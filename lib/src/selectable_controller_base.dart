// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'selection.dart';
import 'selection_anchor.dart';
import 'selection_painter.dart';
import 'selection_paragraph.dart';

/// Abstract base class for selection controllers.
///
/// This class defines the full public API for controlling text selection.
/// `SelectableController` extends this class with concrete implementations.
/// Other controllers (e.g. lazy or composite controllers) can also extend
/// this class to present a unified API.
abstract class SelectableControllerBase extends ChangeNotifier {
  /// Returns `true` if text is selected in any selections.
  bool get isTextSelected;

  /// Returns the selection, or null if a selection with the provided [key]
  /// does not exist. Note, if [key] is not provided, it returns the main
  /// selection (with key 0), which is guaranteed to be non-null.
  Selection? getSelection({int? key});

  /// Hides the selection, if it is not already hidden. Returns `true` if
  /// the selection was updated to be hidden.
  bool hide({Duration? duration, int? key});

  /// Unhides the selection, if it isn't already unhidden. Returns `true` if
  /// the selection was updated to be unhidden.
  bool unhide({Duration? duration, int? key});

  /// If text is selected, deselects all selections. Returns `true` if any
  /// selections were updated to be deselected.
  bool deselectAll();

  /// If text is selected, deselects it. Returns `true` if the selection was
  /// updated to be deselected.
  bool deselect({int? key});

  /// Attempts to select all the words in the text, if any. Returns `true` if
  /// successful.
  bool selectAll({int? key});

  /// Attempts to select the word at [index], returning `true` if successful.
  bool selectWordAtIndex(int index, {int? key});

  /// Attempts to select the words between [start] and [end] indexes, returning
  /// `true` if successful.
  ///
  /// If [end] is `null`, selects the words between [start] up to and including
  /// the last word in the last paragraph.
  bool selectWordsBetweenIndexes(int start, int? end, {int? key});

  /// Attempts to select the words between [start] and [end] selection anchors,
  /// returning `true` if successful.
  bool selectWordsBetweenAnchors(
    SelectionAnchor start,
    SelectionAnchor end, {
    int? key,
  });

  /// Attempts to select the word under [point], returning `true` if successful.
  bool selectWordAtPoint(Offset point, {int? key});

  /// Attempts to select the words between [startPt] and [endPt], returning
  /// `true` if successful.
  bool selectWordsBetweenPoints(Offset startPt, Offset endPt, {int? key});

  /// Returns a String containing the combined text of all render paragraphs
  /// contained in the Selectable. This can be used with `selectWordAtIndex`
  /// and `selectWordsBetweenIndexes` to select a word or words.
  String getContainedText();

  /// Walks the tree of render objects contained in the Selectable, and the
  /// sub-tree of each render paragraph's InlineSpan children in pre-order,
  /// calling [visitor] for each `span` that has content. A span has content
  /// if it is a `TextSpan` whose `text` property is not null, or it is a
  /// `WidgetSpan`.
  ///
  /// When [visitor] returns `true`, the walk will continue. When [visitor]
  /// returns `false`, the walk will end.
  ///
  /// Returns `true` if the walk completed, returns `false` if [visitor]
  /// returned `false`, ending the walk prematurely.
  ///
  /// Note, if there are no render paragraphs contained in the Selectable,
  /// `true` is returned, and [visitor] is not called.
  bool visitContainedSpans(
    bool Function(SelectionParagraph paragraph, InlineSpan span, int index)
    visitor,
  );

  /// Sets the custom selection painter to be used to paint selections.
  void setCustomPainter(SelectionPainter? painter, {int? key});

  /// Returns the selection painter, or null if none.
  SelectionPainter? getCustomPainter({int? key});

  /// Sets the custom rectifier, which is used to convert the raw rectangles of
  /// selected text into the displayed selection rects.
  void setCustomRectifier(
    List<Rect> Function(List<Rect>)? rectifier, {
    int? key,
  });

  /// Returns the custom rectifier, or null if none.
  List<Rect> Function(List<Rect>)? getCustomRectifier({int? key});
}
