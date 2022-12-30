// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'common.dart';
import 'selection_anchor.dart';
import 'selection_controls.dart';
import 'selection_updater.dart';
import 'selections.dart';
import 'tagged_text.dart';

///
/// Selection
///
@immutable
class Selection extends Equatable {
  const Selection({
    this.version = 0,
    this.text,
    this.start,
    this.end,
    this.startPt,
    this.endPt,
    this.startAnchor,
    this.endAnchor,
    this.rects,
    this.isHidden = false,
    this.animationDuration = const Duration(seconds: 1),
    this.rectifier = SelectionRectifiers.identity,
  })  :
        // ignore: unnecessary_null_comparison
        assert(version != null),
        // ignore: unnecessary_null_comparison
        assert(isHidden != null && animationDuration != null),
        // ignore: unnecessary_null_comparison
        assert(rectifier != null);

  @override
  List<Object?> get props => [
        version,
        text,
        start,
        end,
        startPt,
        endPt,
        startAnchor,
        endAnchor,
        rects,
        isHidden,
        animationDuration,
        rectifier,
      ];

  Selection copyWith({
    int? version,
    bool? isHidden,
    Duration? animationDuration,
    List<Rect> Function(List<Rect>)? rectifier,
  }) =>
      Selection(
          version: version ?? this.version,
          text: text,
          start: start,
          end: end,
          startPt: startPt,
          endPt: endPt,
          startAnchor: startAnchor,
          endAnchor: endAnchor,
          rects: rects,
          isHidden: isHidden ?? this.isHidden,
          animationDuration: animationDuration ?? this.animationDuration,
          rectifier: rectifier ?? this.rectifier);

  /// Build version of the Selections that contains this selection.
  final int version;

  /// The selected text, or null if text is not selected.
  final String? text;

  /// The start of the selection, or null if text is not selected.
  final TaggedText? start;

  /// The end of the selection, or null if text is not selected.
  final TaggedText? end;

  /// The local start selection point, or null.
  final Offset? startPt;

  /// The local end selection point, or null.
  final Offset? endPt;

  /// The first word selected, or null.
  final SelectionAnchor? startAnchor;

  /// The last word selected, or null.
  final SelectionAnchor? endAnchor;

  /// Function that converts line rects into selection rects.
  final List<Rect> Function(List<Rect>) rectifier;

  /// The index of the first character in the selection, or null if none.
  int? get startIndex => startAnchor?.startIndex;

  /// The index after the last character in selection, or null if none.
  int? get endIndex => endAnchor?.endIndex;

  /// The selection rect(s), or null.
  ///
  /// It will be from one to, at most, three rects, where the first rect
  /// is the bounding box of the first line, the second rect is the bounding
  /// box of lines 2 through N - 1 (where N is the number of lines), and the
  /// third rect is the bounding box of the last line.
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
  final List<Rect>? rects;

  /// Is selection hidden?
  final bool isHidden;

  /// Duration of the hide/unhide animation, defaults to 1 second.
  final Duration animationDuration;

  /// Is text selected?
  bool get isTextSelected => rects != null;

  /// Returns `true` if the [point] is contained in the selection.
  bool containsPoint(Offset point) => rects?.containsPoint(point) ?? false;

  Selection cleared() => Selection(
        isHidden: isHidden,
        animationDuration: animationDuration,
        rectifier: rectifier,
      );

  /// Returns a new Selection, updated with the provided [paragraphs] and
  /// an optional [dragInfo].
  Selection updatedWith(
    Paragraphs paragraphs,
    SelectionDragInfo? dragInfo,
  ) =>
      updatedSelectionWith(this, paragraphs, dragInfo);
}

///
/// SelectionDragInfo
///
class SelectionDragInfo {
  SelectionDragInfo({
    this.selectionPt,
    this.handleType,
    this.areAnchorsSwapped = false,
  });

  /// The local offset of the long press, double-tap, or drag; or null if none.
  Offset? selectionPt;

  SelectionHandleType? handleType;
  bool areAnchorsSwapped;

  bool get isSelectingWordOrDraggingHandle => selectionPt != null;
  bool get isSelectingWord => selectionPt != null && handleType == null;
  bool get isDraggingHandle => selectionPt != null && handleType != null;
}
