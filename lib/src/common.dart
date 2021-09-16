import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///
/// Iff kDebugMode is true, prints a string representation of the object
/// to the console.
///
void dmPrint(Object object) {
  if (kDebugMode) print(object); // ignore: avoid_print
}

extension SelectableExtOnNum<T extends num> on T {
  ///
  /// Returns true if this number is >= min and < max.
  ///
  bool isInRange(T min, T max) => (this >= min && this < max);
}

///
/// List<Rect> extensions
///
extension SelectableExtOnListOfRect on List<Rect> {
  ///
  /// Returns the index of the first rect in the list that contains
  /// the given [point].
  ///
  /// Searches the list from index [start] to the end of the list.
  ///
  /// Returns -1 if not found.
  ///
  int indexContainingPoint(Offset? point, [int? start]) {
    if (point == null) return -1;
    return indexWhere((rect) => rect.contains(point), start ?? 0);
  }

  ///
  /// Returns true if at least one of the rects in the list contain
  /// the given [point].
  ///
  bool containsPoint(Offset? point) => (indexContainingPoint(point) >= 0);

  ///
  /// Returns a new rect which is the bounding box containing all the
  /// rects in the list.
  ///
  Rect? merged() => fold<Rect?>(
        null,
        (previous, rect) => Rect.fromLTRB(
          math.min(previous?.left ?? rect.left, rect.left),
          math.min(previous?.top ?? rect.top, rect.top),
          math.max(previous?.right ?? rect.right, rect.right),
          math.max(previous?.bottom ?? rect.bottom, rect.bottom),
        ),
      );
}

///
/// Iterable<Rect> extensions
///
extension SelectableExtOnIterableOfRect on Iterable<Rect> {
  ///
  /// Merges the rectangles into, at most, three rects, where the first rect
  /// is the bounding box containing all the rects in the first line, the
  /// second rect is the bounding box of lines 1 through N - 1 (where N is
  /// the number of lines), and the third rect is the bounding box of the
  /// last line.
  ///
  /// Assumes that the rectangles are in 'reading order', i.e. left to right,
  /// top to bottom. Does not support languages that have an alternate order.
  ///
  /// For example:
  /// ```
  ///                 ┌─────────────────┐
  ///                 │ first line      │
  /// ┌───────────────┴─────────────────┤
  /// │ middle line(s)                  │
  /// |                                 |
  /// ├──────────────────────┬──────────┘
  /// │ last line            │
  /// └──────────────────────┘
  /// ```
  List<Rect> mergedToSelectionRects() {
    //
    // IMPORTANT: If this algorithm is changed, please also change the
    //            algorithm in Iterable<TextBox>.mergedToSelectionRects.
    //
    Rect? firstLine;
    Rect? lastLine;
    final rect = fold<Rect?>(
      null,
      (previous, r) {
        if (firstLine == null) {
          firstLine = r;
        } else if (lastLine == null &&
            (r.vCenter < firstLine!.bottom || firstLine!.vCenter > r.top)) {
          firstLine = firstLine!.expandToInclude(r);
        } else if (lastLine == null ||
            (r.vCenter > lastLine!.bottom && lastLine!.vCenter < r.top)) {
          lastLine = r;
        } else {
          lastLine = lastLine!.expandToInclude(r);
        }
        return Rect.fromLTRB(
          math.min(previous?.left ?? r.left, r.left),
          math.min(previous?.top ?? r.top, r.top),
          math.max(previous?.right ?? r.right, r.right),
          math.max(previous?.bottom ?? r.bottom, r.bottom),
        );
      },
    );
    if (firstLine == null) return [];
    if (lastLine == null) return [rect!];
    if (firstLine!.bottom >= lastLine!.top) return [firstLine!, lastLine!];
    return [
      Rect.fromLTRB(firstLine!.left, firstLine!.top, rect!.right, firstLine!.bottom),
      Rect.fromLTRB(rect.left, firstLine!.bottom, rect.right, lastLine!.top),
      Rect.fromLTRB(rect.left, lastLine!.top, lastLine!.right, lastLine!.bottom),
    ];
  }
}

///
/// Iterable<TextBox> extensions
///
extension SelectableExtOnIterableOfTextBox on Iterable<TextBox> {
  ///
  /// Merges the text boxes into, at most, three rects, where the first rect
  /// is the bounding box containing all the rects in the first line, the
  /// second rect is the bounding box of lines 1 through N - 1 (where N is
  /// the number of lines), and the third rect is the bounding box of the
  /// last line.
  ///
  /// Assumes that the text boxes are in 'reading order', i.e. left to right,
  /// top to bottom. Does not support languages that have  an alternate order.
  ///
  /// For example:
  /// ```
  ///                 ┌─────────────────┐
  ///                 │ first line      │
  /// ┌───────────────┴─────────────────┤
  /// │ middle line(s)                  │
  /// |                                 |
  /// ├──────────────────────┬──────────┘
  /// │ last line            │
  /// └──────────────────────┘
  /// ```
  List<Rect> mergedToSelectionRects() {
    //
    // IMPORTANT: If this algorithm is changed, please also change the
    //            algorithm in Iterable<Rect>.mergedToSelectionRects.
    //
    Rect? firstLine;
    Rect? lastLine;
    final rect = fold<Rect?>(
      null,
      (previous, r) {
        if (firstLine == null) {
          firstLine = r.toRect();
        } else if (lastLine == null &&
            (r.vCenter < firstLine!.bottom || firstLine!.vCenter > r.top)) {
          firstLine = firstLine!.expandToIncludeTextBox(r);
        } else if (lastLine == null ||
            (r.vCenter > lastLine!.bottom && lastLine!.vCenter < r.top)) {
          lastLine = r.toRect();
        } else {
          lastLine = lastLine!.expandToIncludeTextBox(r);
        }
        return Rect.fromLTRB(
          math.min(previous?.left ?? r.left, r.left),
          math.min(previous?.top ?? r.top, r.top),
          math.max(previous?.right ?? r.right, r.right),
          math.max(previous?.bottom ?? r.bottom, r.bottom),
        );
      },
    );
    if (firstLine == null) return [];
    if (lastLine == null) return [rect!];
    if (firstLine!.bottom >= lastLine!.top) return [firstLine!, lastLine!];
    return [
      Rect.fromLTRB(firstLine!.left, firstLine!.top, rect!.right, firstLine!.bottom),
      Rect.fromLTRB(rect.left, firstLine!.bottom, rect.right, lastLine!.top),
      Rect.fromLTRB(rect.left, lastLine!.top, lastLine!.right, lastLine!.bottom),
    ];
  }
}

///
/// Rect extensions
///
extension SelectableExtOnRect on Rect {
  ///
  /// Returns a new rectangle which is the bounding box containing this
  /// rectangle and the given text box.
  ///
  Rect expandToIncludeTextBox(TextBox other) {
    return Rect.fromLTRB(
      math.min(left, other.left),
      math.min(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom),
    );
  }

  ///
  /// If right < left or bottom < top, returns a new normalized rectangle,
  /// otherwise just returns `this`.
  ///
  Rect normalized() {
    if (right < left) {
      if (bottom < top) {
        return Rect.fromLTRB(right, bottom, left, top);
      }
      return Rect.fromLTRB(right, top, left, bottom);
    } else if (bottom < top) {
      return Rect.fromLTRB(left, bottom, right, top);
    }
    return this;
  }

  /// The vertical center.
  double get vCenter => (top + bottom) / 2.0;

  /// The horizontal center.
  double get hCenter => (left + right) / 2.0;
}

///
/// TextBox extensions
///
extension SelectableTextBoxExt on TextBox {
  /// The vertical center.
  double get vCenter => (top + bottom) / 2.0;

  /// The horizontal center.
  double get hCenter => (left + right) / 2.0;

  ///
  /// Returns a new text box translated by the given offset.
  ///
  /// To translate a text box by separate x and y components rather than by an
  /// [Offset], consider [translate].
  ///
  TextBox shift(Offset offset) {
    return TextBox.fromLTRBD(
        left + offset.dx, top + offset.dy, right + offset.dx, bottom + offset.dy, direction);
  }

  ///
  /// Returns a new text box with translateX added to the x components and
  /// translateY added to the y components.
  ///
  /// To translate a text box by an [Offset] rather than by separate x and y
  /// components, consider [shift].
  ///
  TextBox translate(double translateX, double translateY) {
    return TextBox.fromLTRBD(
        left + translateX, top + translateY, right + translateX, bottom + translateY, direction);
  }

  ///
  /// Returns a new text box with edges moved outwards by the given delta.
  ///
  TextBox inflate(double delta) {
    return TextBox.fromLTRBD(left - delta, top - delta, right + delta, bottom + delta, direction);
  }

  ///
  /// Returns a new text box with edges moved inwards by the given delta.
  ///
  TextBox deflate(double delta) => inflate(-delta);

  ///
  /// Returns a new rectangle which is the bounding box containing this
  /// text box and the given text box.
  ///
  Rect expandToInclude(TextBox other) {
    return Rect.fromLTRB(
      math.min(left, other.left),
      math.min(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom),
    );
  }
}

const DeepCollectionEquality _equality = DeepCollectionEquality();

///
/// Returns `true` iff [list1] and [list2] are equal.
///
bool areEqualLists(List? list1, List? list2) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  final length = list1.length;
  if (length != list2.length) return false;

  for (var i = 0; i < length; i++) {
    final dynamic unit1 = list1[i];
    final dynamic unit2 = list2[i];

    if (unit1 is Iterable || unit1 is Map) {
      if (!_equality.equals(unit1, unit2)) return false;
      // ignore: avoid_dynamic_calls
    } else if (unit1?.runtimeType != unit2?.runtimeType) {
      return false;
    } else if (unit1 != unit2) {
      return false;
    }
  }
  return true;
}
