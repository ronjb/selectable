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
  });

  // Note, the props are ordered cheapest-to-compare first, so that equality
  // checks of unequal selections bail before comparing the potentially large
  // `rects` and `text` values.
  @override
  List<Object?> get props => [
    version,
    isHidden,
    animationDuration,
    startPt,
    endPt,
    start,
    end,
    startAnchor,
    endAnchor,
    rects,
    text,
    rectifier,
  ];

  Selection copyWith({
    int? version,
    bool? isHidden,
    Duration? animationDuration,
    List<Rect> Function(List<Rect>)? rectifier,
  }) => Selection(
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
    rectifier: rectifier ?? this.rectifier,
  );

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
  Selection updatedWith(Paragraphs paragraphs, SelectionDragInfo? dragInfo) =>
      updatedSelectionWith(this, paragraphs, dragInfo);
}

///
/// SelectionDragInfo
///
class SelectionDragInfo {
  SelectionDragInfo({
    Offset? selectionPt,
    SelectionHandleType? handleType,
    this.areAnchorsSwapped = false,
  }) : _selectionPt = selectionPt,
       _handleType = handleType;

  /// The local offset of the long press, double-tap, or drag; or null if none.
  Offset? get selectionPt => _selectionPt;
  Offset? _selectionPt;
  set selectionPt(Offset? value) {
    _selectionPt = value;
    _needsCompute = true;
  }

  SelectionHandleType? get handleType => _handleType;
  SelectionHandleType? _handleType;
  set handleType(SelectionHandleType? value) {
    _handleType = value;
    _needsCompute = true;
  }

  // Note, this is a plain field because it is mutated by the selection
  // computation itself, so it must not invalidate the computation.
  bool areAnchorsSwapped;

  bool get isSelectingWordOrDraggingHandle => selectionPt != null;
  bool get isSelectingWord => selectionPt != null && handleType == null;
  bool get isDraggingHandle => selectionPt != null && handleType != null;

  /// Returns `true` if the selection needs to be recomputed for the current
  /// drag state and paragraph cache [version]. For internal use.
  bool needsComputeForVersion(int version) =>
      _needsCompute || _computedVersion != version;

  /// Records that the selection was computed for the current drag state and
  /// paragraph cache [version]. For internal use.
  void markComputedForVersion(int version) {
    _needsCompute = false;
    _computedVersion = version;
  }

  bool _needsCompute = true;
  int _computedVersion = 0;
}
