// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

part of 'selectable.dart';

/// Concrete implementation of [SelectableControllerBase] that manages
/// selections, custom painters, and custom rectifiers.
class SelectableController extends SelectableControllerBase {
  @override
  bool get isTextSelected => _selections.isTextSelected;

  @override
  Selection? getSelection({int? key}) {
    final k = key ?? 0;
    return _selections[k] ??
        (k == 0
            ? Selection(
                rectifier: _rectifiers[k] ?? SelectionRectifiers.identity,
              )
            : null);
  }

  @override
  bool hide({Duration? duration, int? key}) {
    final k = key ?? 0;
    final selection = _selections[k];
    if (selection != null && !selection.isHidden) {
      _selections[k] = selection.copyWith(
        isHidden: true,
        animationDuration: duration,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  bool unhide({Duration? duration, int? key}) {
    final k = key ?? 0;
    final selection = _selections[k];
    if (selection != null && selection.isHidden) {
      _selections[k] = selection.copyWith(
        isHidden: false,
        animationDuration: duration,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  bool deselectAll() {
    final didDeselectAny = _selections.deselectAll();
    if (didDeselectAny) {
      notifyListeners();
    }
    return didDeselectAny;
  }

  @override
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

  @override
  bool selectAll({int? key}) {
    return selectWordsBetweenIndexes(0, null, key: key);
  }

  @override
  bool selectWordAtIndex(int index, {int? key}) =>
      selectWordsBetweenIndexes(index, index, key: key);

  @override
  bool selectWordsBetweenIndexes(int start, int? end, {int? key}) {
    assert(end == null || start <= end);

    SelectionAnchor? startAnchor, endAnchor;
    SelectionParagraph? lastParagraph;
    var lastCharIndexInLastParagraph = 0;

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
          if (end == null) {
            lastParagraph = paragraph;
            lastCharIndexInLastParagraph = index + span.text!.length;
          } else if (end == start) {
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

    if (startAnchor != null && end == null) {
      endAnchor = lastParagraph!.anchorAtCharIndex(
        lastCharIndexInLastParagraph - 1,
      );
    }

    if (startAnchor != null && endAnchor != null) {
      return selectWordsBetweenAnchors(startAnchor!, endAnchor!, key: key);
    }

    return false;
  }

  @override
  bool selectWordsBetweenAnchors(
    SelectionAnchor start,
    SelectionAnchor end, {
    int? key,
  }) {
    if (start <= end) {
      final startPt = start.rects.first.center;

      // When justification is turned on, centerRight.dx can be slightly
      // outside of of the paragraph's rect, so we subtract 2.0 so it won't be.
      final endPt = end.rects.last.centerRight - const Offset(2.0, 0);

      return selectWordsBetweenPoints(startPt, endPt, key: key);
    } else {
      assert(false);
    }

    return false;
  }

  @override
  bool selectWordAtPoint(Offset point, {int? key}) =>
      selectWordsBetweenPoints(point, point, key: key);

  @override
  bool selectWordsBetweenPoints(Offset startPt, Offset endPt, {int? key}) {
    final k = key ?? 0;
    if (k < 0) return false;

    // First, clear and unhide the selection, or create it if it doesn't exist.
    var selection =
        _selections[k]?.cleared().copyWith(isHidden: false) ??
        Selection(rectifier: _rectifiers[k] ?? SelectionRectifiers.identity);

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

  @override
  String getContainedText() {
    final buff = StringBuffer();
    for (final paragraph in _selections.cachedParagraphs.list) {
      buff.write(paragraph.text);
    }
    return buff.toString();
  }

  @override
  bool visitContainedSpans(
    bool Function(SelectionParagraph paragraph, InlineSpan span, int index)
    visitor,
  ) {
    for (final paragraph in _selections.cachedParagraphs.list) {
      if (!paragraph.visitChildSpans(
        (span, index) => visitor(paragraph, span, index),
      )) {
        return false;
      }
    }
    return true;
  }

  @override
  void setCustomPainter(SelectionPainter? painter, {int? key}) {
    final k = key ?? 0;
    if (painter == null) {
      if (_painters.containsKey(k)) {
        _painters.remove(k);
        notifyListeners();
      }
    } else {
      _painters[k] = painter;
      notifyListeners();
    }
  }

  @override
  SelectionPainter? getCustomPainter({int? key}) => _painters[key ?? 0];

  @override
  void setCustomRectifier(
    List<Rect> Function(List<Rect>)? rectifier, {
    int? key,
  }) {
    final k = key ?? 0;
    if (_rectifiers[k] != rectifier) {
      final selection = _selections[k];
      if (rectifier == null) {
        if (_rectifiers.containsKey(k)) {
          _rectifiers.remove(k);

          if (selection != null) {
            _selections[k] = selection.copyWith(
              version: selection.version - 1,
              rectifier: SelectionRectifiers.identity,
            );
          }
          notifyListeners();
        }
      } else {
        _rectifiers[k] = rectifier;
        if (selection != null) {
          _selections[k] = selection.copyWith(
            version: selection.version - 1,
            rectifier: rectifier,
          );
        }
        notifyListeners();
      }
    }
  }

  @override
  List<Rect> Function(List<Rect>)? getCustomRectifier({int? key}) =>
      _rectifiers[key ?? 0];

  //
  // PRIVATE
  //

  final _selections = Selections();
  final _painters = <int, SelectionPainter>{};
  final _rectifiers = <int, List<Rect> Function(List<Rect>)>{};

  /// Updates the [Selections]. This is called by Selectable when the
  /// selection changes. It should not be called by any other code.
  ///
  /// Returns `true` if something changed and `notifyListeners` was called.
  bool _updateWithSelections(Selections newSelections) {
    final changed = _selections.updateWithSelections(newSelections);
    if (changed) notifyListeners();
    return changed;
  }
}
