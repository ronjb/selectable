// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

part of 'selectable.dart';

/// Provides a way to be notified of selection changes and a way to select
/// and deselect text.
class SelectableController extends ChangeNotifier {
  /// Returns `true` if text is selected in any selections.
  bool get isTextSelected => _selections.isTextSelected;

  /// Returns the selection, or null if a selection with the provided [key]
  /// does not exist. Note, if [key] is not provided, it returns the main
  /// selection (with key 0), which is guaranteed to not fail.
  Selection? getSelection({int? key}) => _selections[key ?? 0];

  /// Returns the selected text of the main selection, or null if text is
  /// not selected.
  @Deprecated('Use `getSelection().text` instead. '
      'This feature was deprecated after v0.1.3')
  String? get text => _selections.main.text;

  /// Returns the start of the main selection, or null if text is not
  /// selected.
  @Deprecated('Use `getSelection().start` instead. '
      'This feature was deprecated after v0.1.3')
  TaggedText? get selectionStart => _selections.main.start;

  /// Returns the end of the main selection, or null if text is not
  /// selected.
  @Deprecated('Use `getSelection().end` instead. '
      'This feature was deprecated after v0.1.3')
  TaggedText? get selectionEnd => _selections.main.end;

  /// Returns the main selection's rect(s), or null if text is not selected.
  @Deprecated('Use `getSelection().rects` instead. '
      'This feature was deprecated after v0.1.3')
  List<Rect>? get rects => _selections.main.rects;

  /// Hides the selection, if it is not already hidden. Returns `true` if
  /// the selection was updated to be hidden.
  bool hide({Duration? duration, int? key}) {
    final k = key ?? 0;
    final selection = _selections[k];
    if (selection != null && !selection.isHidden) {
      _selections[k] =
          selection.copyWith(isHidden: true, animationDuration: duration);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Unhides the selection, if it isn't already unhidden. Returns `true` if
  /// the selection was updated to be unhidden.
  bool unhide({Duration? duration, int? key}) {
    final k = key ?? 0;
    final selection = _selections[k];
    if (selection != null && selection.isHidden) {
      _selections[k] =
          selection.copyWith(isHidden: false, animationDuration: duration);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// If text is selected, deselects it. Returns `true` if any selections
  /// were updated to be deselected.
  bool deselectAll({int? key}) {
    final didDeselectAny = _selections.deselectAll();
    if (didDeselectAny) {
      notifyListeners();
    }
    return didDeselectAny;
  }

  /// If text is selected, deselects it. Returns `true` if the selection was
  /// updated to be deselected.
  bool deselect({int? key}) {
    final k = key ?? 0;
    final selection = _selections[k];
    if (selection != null && selection.isTextSelected) {
      _selections[k] = selection.cleared();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Attempts to select the word at [index], returning `true` if successful.
  bool selectWordAtIndex(int index, {int? key}) =>
      selectWordsBetweenIndexes(index, index, key: key);

  /// Attempts to select the words between [start] and [end] indexes, returning
  /// `true` if successful.
  bool selectWordsBetweenIndexes(int start, int end, {int? key}) {
    // ignore: unnecessary_null_comparison
    assert(start != null && end != null && start <= end);

    SelectionAnchor? startAnchor, endAnchor;
    visitContainedSpans((paragraph, span, index) {
      if (span is TextSpan) {
        // `s` is `start` in the context of the current paragraph.
        final s = start - paragraph.firstCharIndex;
        if (startAnchor == null &&
            s >= index &&
            s < index + span.text!.length) {
          startAnchor = paragraph.anchorAtCharIndex(s);
        }

        if (startAnchor != null) {
          if (end == start) {
            endAnchor = startAnchor;
          } else {
            // `e` is `end` in the context of the current paragraph.
            final e = end - paragraph.firstCharIndex - 1;
            if (e >= index && e < index + span.text!.length) {
              endAnchor = paragraph.anchorAtCharIndex(e);
            }
          }
        }
      }

      // Continue walking the span tree until the endAnchor has been found.
      return endAnchor == null;
    });

    if (startAnchor != null && endAnchor != null) {
      return selectWordsBetweenAnchors(startAnchor!, endAnchor!, key: key);
    }

    return false;
  }

  /// Attempts to select the words between [start] and [end] selection anchors,
  /// returning `true` if successful.
  bool selectWordsBetweenAnchors(
    SelectionAnchor start,
    SelectionAnchor end, {
    int? key,
  }) {
    // ignore: unnecessary_null_comparison
    assert(start != null && end != null && start <= end);

    // ignore: unnecessary_null_comparison
    if (start != null && end != null && start <= end) {
      final startPt = start.rects.first.center;
      final endPt = end.rects.last.centerRight;
      return selectWordsBetweenPoints(startPt, endPt, key: key);
    }

    return false;
  }

  /// Attempts to select the word under [point], returning `true` if successful.
  bool selectWordAtPoint(Offset point, {int? key}) =>
      selectWordsBetweenPoints(point, point, key: key);

  /// Attempts to select the words between [startPt] and [endPt], returning
  /// `true` if successful.
  bool selectWordsBetweenPoints(Offset startPt, Offset endPt, {int? key}) {
    final k = key ?? 0;
    if (k < 0) return false;

    // First, clear and unhide the selection, or create it if it doesn't exist.
    var selection = _selections[k]?.cleared().copyWith(isHidden: false) ??
        const Selection();

    // Next, attempt to select the word under the first point.
    selection = selection.updatedWith(
      _selections.cachedParagraphs,
      SelectionDragInfo(selectionPt: startPt),
    );

    // Finally, if that worked, and endPt != startPt, attempt to extend the
    // selection to include the end point.
    if (selection.isTextSelected && endPt != startPt) {
      selection = selection.updatedWith(
        _selections.cachedParagraphs,
        SelectionDragInfo(
          selectionPt: endPt,
          handleType: SelectionHandleType.right,
        ),
      );
    }

    if (selection.isTextSelected) {
      _selections[k] = selection;
      notifyListeners();
      return true;
    } else if (startPt == endPt) {
      // dmPrint('WARNING: Selectable selectWordAtPoint($startPt) failed.');
    } else {
      // dmPrint('WARNING: Selectable '
      //     'selectWordsBetweenPoints($startPt, $endPt) failed.');
    }

    return false;
  }

  /// Returns a String containing the combined text of all render paragraphs
  /// contained in the Selectable. This can be used with `selectWordAtIndex`
  /// and `selectWordsBetweenIndexes` to select a word or words.
  String getContainedText() {
    final buff = StringBuffer();
    for (final paragraph in _selections.cachedParagraphs.list) {
      buff.write(paragraph.text);
    }
    return buff.toString();
  }

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
          visitor) {
    // ignore: unnecessary_null_comparison
    if (visitor != null) {
      for (final paragraph in _selections.cachedParagraphs.list) {
        if (!paragraph.visitChildSpans(
            (span, index) => visitor(paragraph, span, index))) {
          return false;
        }
      }
    }
    return true;
  }

  //
  // PRIVATE STUFF
  //

  /// Updates the [Selections]. This is called by Selectable when the
  /// selection changes. It should not be called by any other code.
  ///
  /// Returns `true` if something changed and `notifyListeners` was called.
  bool _updateWithSelections(Selections newSelections) {
    final changed = _selections.updateWithSelections(newSelections);
    if (changed) notifyListeners();
    return changed;
  }

  final _selections = Selections();
}
