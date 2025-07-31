// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// If kDebugMode is `true`, prints a string representation of the object
/// to the console.
void dmPrint(Object object) {
  if (kDebugMode) print(object);
}

/// The maximum safe integer value for dart code that might be compiled
/// to javascript (i.e. used in a web app).
///
/// See: https://dart.dev/guides/language/language-tour#numbers
const maxJsInt = 0x1FFFFFFFFFFFFF; // 2^53 - 1

/// The minimum safe integer value for dart code that might be compiled
/// to javascript (i.e. used in a web app).
///
/// See: https://dart.dev/guides/language/language-tour#numbers
const minJsInt = -0x20000000000000; // -2^53

const DeepCollectionEquality _equality = DeepCollectionEquality();

/// Returns `true` if [a] and [b] are equal.
// ignore: strict_raw_type
bool areEqualLists(List? a, List? b) => _equality.equals(a, b);

/// Returns `true` if [a] and [b] are equal.
// ignore: strict_raw_type
bool areEqualMaps(Map? a, Map? b) => _equality.equals(a, b);

extension SelectableExtOnInt on int {
  /// Returns n + 1, unless n >= `maxJsInt`, in which case it returns [wrapTo],
  /// which defaults to 1.
  int incWithJsSafeWrap({int wrapTo = 1}) =>
      (this < maxJsInt ? this + 1 : wrapTo);
}

extension SelectableExtOnNum<T extends num> on T {
  /// Returns `true` if this number is >= min and < max.
  bool isInRange(T min, T max) => (this >= min && this < max);
}

extension SelectableExtOnIterable<T> on Iterable<T> {
  /// Returns `true` if the length of this iterable is greater than [l].
  ///
  /// This method is more efficient than using `length > l` because this method
  /// stops iterating once it knows the length exceeds [l], whereas calling
  /// `length` iterates through the whole list.
  bool lengthIsGreaterThan(int l) {
    var count = 0;
    final it = iterator;
    while (it.moveNext()) {
      if (++count > l) return true;
    }
    return l < 0;
  }
}

extension SelectableExtOnScrollController on ScrollController {
  bool get hasOneClient => hasClients && !positions.lengthIsGreaterThan(1);

  int get clientCount => hasClients ? positions.length : 0;
}

///
/// `List<Rect>` extensions
///
extension SelectableExtOnListOfRect on List<Rect> {
  /// Returns the index of the first rect in the list that contains [point].
  ///
  /// Searches the list from index [start] to the end of the list.
  ///
  /// Returns -1 if not found.
  int indexContainingPoint(Offset? point, [int? start]) {
    if (point == null) return -1;
    return indexWhere((rect) => rect.contains(point), start ?? 0);
  }

  /// Returns `true` if at least one of the rects in the list contains [point].
  bool containsPoint(Offset? point) => (indexContainingPoint(point) >= 0);

  /// Returns a new rect which is the bounding box containing all the
  /// rects in the list.
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

// We want these function to be in a namespace.
// ignore: avoid_classes_with_only_static_members
class SelectionRectifiers {
  static List<Rect> identity(List<Rect> rects) => rects;
  static List<Rect> merged(List<Rect> rects) => rects.mergedToSelectionRects();
  static List<Rect> mergedRtl(List<Rect> rects) =>
      rects.mergedToSelectionRectsRtl();
}

///
/// `Iterable<Rect>` extensions
///
extension SelectableExtOnIterableOfRect on Iterable<Rect> {
  /// Merges the rectangles into, at most, three rects, where the first rect
  /// is the bounding box containing all the rects in the first line, the
  /// second rect is the bounding box of lines 1 through N - 1 (where N is
  /// the number of lines), and the third rect is the bounding box of the
  /// last line.
  ///
  /// Assumes that the rectangles are in 'reading order', i.e. left to right,
  /// top to bottom. Does not support languages that have an alternate order.
  ///
  /// For example, if [rtl] is `false`:
  /// ```sketch
  ///                 ┌─────────────────┐
  ///                 │ first line      │
  /// ┌───────────────┴─────────────────┤
  /// │ middle line(s)                  │
  /// |                                 |
  /// ├──────────────────────┬──────────┘
  /// │ last line            │
  /// └──────────────────────┘
  /// ```
  ///
  /// Or, if [rtl] is true:
  /// ```sketch
  /// ┌─────────────────┐
  /// │ first line      │
  /// ├─────────────────┴───────────────┐
  /// │ middle line(s)                  │
  /// |                                 |
  /// └──────────┬──────────────────────┤
  ///            │ last line            │
  ///            └──────────────────────┘
  /// ```

  List<Rect> mergedToSelectionRects({bool rtl = false}) {
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

    List<Rect> rects;
    if (rtl) {
      rects = [
        Rect.fromLTRB(
            rect!.left, firstLine!.top, firstLine!.right, firstLine!.bottom),
        Rect.fromLTRB(rect.left, firstLine!.bottom, rect.right, lastLine!.top),
        Rect.fromLTRB(
            lastLine!.left, lastLine!.top, rect.right, lastLine!.bottom),
      ];
      // print('merged rects: $rects');
    } else {
      rects = [
        Rect.fromLTRB(
            firstLine!.left, firstLine!.top, rect!.right, firstLine!.bottom),
        Rect.fromLTRB(rect.left, firstLine!.bottom, rect.right, lastLine!.top),
        Rect.fromLTRB(
            rect.left, lastLine!.top, lastLine!.right, lastLine!.bottom),
      ];
      // print('rtl merged rects: $rects');
    }

    return rects;
  }

  /// Merges the rectangles into, at most, three rects, where the first rect
  /// is the bounding box containing all the rects in the first line, the
  /// second rect is the bounding box of lines 1 through N - 1 (where N is
  /// the number of lines), and the third rect is the bounding box of the
  /// last line.
  ///
  /// Assumes that the rectangles are in right-to-left order, top to bottom.
  ///
  /// For example:
  /// ```sketch
  /// ┌─────────────────┐
  /// │ first line      │
  /// ├─────────────────┴───────────────┐
  /// │ middle line(s)                  │
  /// |                                 |
  /// └──────────┬──────────────────────┤
  ///            │ last line            │
  ///            └──────────────────────┘
  /// ```
  List<Rect> mergedToSelectionRectsRtl() => mergedToSelectionRects(rtl: true);

  Iterable<Rect> rounded() => map((rect) => Rect.fromLTRB(
      rect.left.roundToDouble(),
      rect.top.roundToDouble(),
      rect.right.roundToDouble(),
      rect.bottom.roundToDouble()));
}

///
/// Rect extensions
///
extension SelectableExtOnRect on Rect {
  /// Returns a new rectangle which is the bounding box containing this
  /// rectangle and [other].
  Rect expandToIncludeTextBox(TextBox other) {
    return Rect.fromLTRB(
      math.min(left, other.left),
      math.min(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom),
    );
  }

  /// If right < left or bottom < top, returns a new normalized rectangle,
  /// otherwise just returns `this`.
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

  /// Whether [other] is within [maxDistance] of this rect. [maxDistance]
  /// defaults to 10.
  bool isNear(Rect other, {double maxDistance = 10.0}) {
    if (right + maxDistance <= other.left ||
        other.right + maxDistance <= left) {
      return false;
    }
    if (bottom + maxDistance <= other.top ||
        other.bottom + maxDistance <= top) {
      return false;
    }
    return true;
  }
}

///
/// TextBox extensions
///
extension SelectableExtOnTextBox on TextBox {
  /// The vertical center.
  double get vCenter => (top + bottom) / 2.0;

  /// The horizontal center.
  double get hCenter => (left + right) / 2.0;

  /// Returns a new text box translated by [offset].
  ///
  /// To translate a text box by separate x and y components rather than by an
  /// [Offset], consider [translate].
  TextBox shift(Offset offset) {
    return TextBox.fromLTRBD(left + offset.dx, top + offset.dy,
        right + offset.dx, bottom + offset.dy, direction);
  }

  /// Returns a new text box with translateX added to the x components and
  /// translateY added to the y components.
  ///
  /// To translate a text box by an [Offset] rather than by separate x and y
  /// components, consider [shift].
  TextBox translate(double translateX, double translateY) {
    return TextBox.fromLTRBD(left + translateX, top + translateY,
        right + translateX, bottom + translateY, direction);
  }

  /// Returns a new text box with edges inflated by [delta].
  TextBox inflate(double delta) {
    return TextBox.fromLTRBD(
        left - delta, top - delta, right + delta, bottom + delta, direction);
  }

  /// Returns a new text box with edges deflated by [delta].
  TextBox deflate(double delta) => inflate(-delta);

  /// Returns a new rectangle which is the bounding box containing this
  /// text box and [other].
  Rect expandToInclude(TextBox other) {
    return Rect.fromLTRB(
      math.min(left, other.left),
      math.min(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom),
    );
  }
}

extension SelectableExtOnList<T> on List<T> {
  /// Returns the position in this list where the [compare] function returns 0,
  /// otherwise returns -1.
  ///
  /// If the list isn't sorted according to the [compare] function, the result
  /// is unpredictable.
  ///
  /// The [compare] function must return a negative integer if the element
  /// is ordered before the matching element, a positive integer if the element
  /// is ordered after the matching element, and zero if the element is equal to
  /// the matching element.
  int binarySearchWithCompare(int Function(T) compare) {
    var min = 0;
    var max = length;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      final element = this[mid];
      final comp = compare(element);
      if (comp == 0) {
        return mid;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }
}
