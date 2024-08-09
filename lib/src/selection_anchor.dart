// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'common.dart';
import 'inline_span_ext.dart';
import 'selection_paragraph.dart';
import 'tagged_text.dart';

/// The render paragraph index and text selection for the start or end anchor.
@immutable
class SelectionAnchor extends Equatable implements Comparable<SelectionAnchor> {
  const SelectionAnchor(
    this.paragraphIndex,
    this.firstCharIndex,
    this.textSel,
    this.rects,
  )   :
        // In case this is called from non-null-safe code.
        // ignore: unnecessary_null_comparison
        assert(paragraphIndex != null && textSel != null && rects != null),
        assert(paragraphIndex >= 0);

  /// Index of this anchor's paragraph in the global paragraph list.
  final int paragraphIndex;

  /// Index of the first character of this anchor's paragraph in the global
  /// paragraph list.
  final int firstCharIndex;

  /// A range of text that represents the selected word in this anchor's
  /// paragraph.
  final TextSelection textSel;

  /// Rectangle(s) for the selected word. It can be more than one rectangle
  /// if the word is wrapped across multiple lines.
  final List<Rect> rects;

  /// Returns the index of this anchor's first character in the global
  /// paragraph list.
  int get startIndex => firstCharIndex + textSel.start;

  /// Returns the index after this anchor's last character in the global
  /// paragraph list.
  int get endIndex => firstCharIndex + textSel.end;

  /// Returns a new SelectionAnchor with the selected word's rectangles
  /// inflated by [delta].
  SelectionAnchor copyInflated(double delta) => SelectionAnchor(
        paragraphIndex,
        firstCharIndex,
        textSel,
        rects.map((rect) => rect.inflate(delta)).toList(),
      );

  /// Returns `true` if the selected word's rectangle(s) contain the [point].
  bool containsPoint(Offset? point) => rects.containsPoint(point);

  /// Returns the square of the distance from the center of the rectangle that
  /// is closest to the given [point].
  ///
  /// Uses distance squared to avoid the expensive square root calculation.
  double centerDistanceSquaredFromPoint(Offset point) {
    double? minDistance;
    for (final rect in rects) {
      final center = rect.center;
      final distance = (center.distanceSquared - point.distanceSquared).abs();
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance ?? double.infinity;
  }

  bool operator <(SelectionAnchor? other) => (compareTo(other) < 0);
  bool operator <=(SelectionAnchor? other) => (compareTo(other) <= 0);
  bool operator >(SelectionAnchor? other) => (compareTo(other) > 0);
  bool operator >=(SelectionAnchor? other) => (compareTo(other) >= 0);

  @override
  int compareTo(SelectionAnchor? other) {
    var v = (other == null ? 1 : 0);
    if (v == 0) v = paragraphIndex - other!.paragraphIndex;
    if (v == 0) {
      v = (textSel.start + firstCharIndex) -
          (other!.textSel.start + other.firstCharIndex);
    }
    if (v == 0) {
      v = (textSel.end + firstCharIndex) -
          (other!.textSel.end + other.firstCharIndex);
    }
    return v;
  }

  @override
  List<Object?> get props =>
      [paragraphIndex, firstCharIndex, textSel.start, textSel.end];

  /// Creates and returns the [TaggedText] object for this anchor.
  TaggedText? taggedTextWithParagraphs(
    List<SelectionParagraph> paragraphs, {
    bool end = false,
  }) {
    TaggedText? taggedText;
    if (paragraphs.length > paragraphIndex) {
      taggedText = paragraphs[paragraphIndex]
          .rp
          ?.text
          .taggedTextForIndex(end ? textSel.end : textSel.start, end: end);
    }
    if (taggedText == null) {
      final rp = paragraphs[paragraphIndex].rp;
      dmPrint('ERROR: Selectable '
          'taggedTextForIndex(${end ? textSel.end : textSel.start},'
          ' end: ${end ? 'true' : 'false'}) failed for string: '
          '${rp?.text.toPlainText(includeSemanticsLabels: false)}');
      assert(false);
    }
    return taggedText;
  }
}
