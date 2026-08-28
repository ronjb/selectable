// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';

import 'common.dart';
import 'inline_span_ext.dart';
import 'selection_anchor.dart';
import 'string_utils.dart';
import 'tagged_text.dart';

///
/// Render paragraph data.
///
class SelectionParagraph implements Comparable<SelectionParagraph> {
  const SelectionParagraph({
    required this.rp,
    required this.rect,
    required this.text,
    required this.trimmedSel,
    required this.paragraphIndex,
    required this.firstCharIndex,
  });

  final RenderParagraph? rp;
  final Rect rect;
  final String text;
  final TextSelection trimmedSel;
  final int paragraphIndex;
  final int firstCharIndex;

  /// Accepts nullable [other] intentionally. Returns positive when [other]
  /// is null.
  @override
  int compareTo(SelectionParagraph? other) {
    var v = (other == null ? 1 : 0);
    if (v == 0) v = paragraphIndex - other!.paragraphIndex;
    if (v == 0) v = firstCharIndex - other!.firstCharIndex;
    return v;
  }

  /// Returns `true` if the text direction is right-to-left.
  bool get isRtl => rp?.textDirection == TextDirection.rtl;

  /// Returns a new `SelectionParagraph` or `null` if the provided
  /// `RenderParagraph` has no size (i.e. has not undergone layout),
  /// or if its `text` is empty or just whitespace.
  ///
  /// The [ancestor] must be an ancestor of the provided `RenderParagraph`,
  /// and is used to determine the offset of this paragraph's rect.
  static SelectionParagraph? from(
    RenderParagraph rp, {
    required RenderObject ancestor,
    int paragraphIndex = 0,
    int firstCharIndex = 0,
  }) {
    if (!rp.hasSize) return null;

    try {
      final span = rp.text;
      if (span is TextSpan) {
        var text = span.toPlainText(
          includeSemanticsLabels: false,
          includePlaceholders: true,
        );
        final size = rp.textSize;
        var height = size.height;

        // If the paragraph clips overflowing lines, they are invisible, so
        // exclude them from selection by truncating the text at the start of
        // the first clipped line and limiting the height to the clip bounds.
        // For example, float_column renders a justified paragraph that wraps
        // at floated widget boundaries as multiple text widgets, appending a
        // hidden copy of the next part's leading word on an extra clipped
        // line to all but the last, to force justification of the line
        // before it.
        if (rp.overflow == TextOverflow.clip &&
            height > rp.size.height + precisionErrorTolerance) {
          height = rp.size.height;
          text = text.substring(
            0,
            _indexOfFirstClippedCharacter(rp, height, text.length),
          );
        }

        final trimmedSel = createTextSelection(text);
        if (trimmedSel != null) {
          final offset = rp.getTransformTo(ancestor).getTranslation();
          final rect = Rect.fromLTWH(offset.x, offset.y, size.width, height);
          return SelectionParagraph(
            rp: rp,
            rect: rect,
            text: text,
            trimmedSel: trimmedSel,
            paragraphIndex: paragraphIndex,
            firstCharIndex: firstCharIndex,
          );
        }
      }
    } catch (e) {
      // dmPrint('ERROR: In Selectable, SelectionParagraph.from(): $e');
    }

    return null;
  }

  /// Returns a copy of this paragraph with zero or more property values
  /// updated.
  SelectionParagraph copyWith({
    RenderParagraph? rp,
    Rect? rect,
    String? text,
    TextSelection? trimmedSel,
    int? paragraphIndex,
    int? firstCharIndex,
  }) => SelectionParagraph(
    rp: rp ?? this.rp,
    rect: rect ?? this.rect,
    text: text ?? this.text,
    trimmedSel: trimmedSel ?? this.trimmedSel,
    paragraphIndex: paragraphIndex ?? this.paragraphIndex,
    firstCharIndex: firstCharIndex ?? this.firstCharIndex,
  );

  /// Returns a new [SelectionAnchor] at the provided [Offset].
  SelectionAnchor? anchorAtPt(
    Offset pt, {
    bool onlyIfInRect = true,
    bool trim = true,
  }) {
    return anchorAtRange(
      wordBoundaryAtPt(pt, onlyIfInRect: onlyIfInRect),
      trim: trim,
    );
  }

  /// Returns a new [SelectionAnchor] at the provided character index.
  SelectionAnchor? anchorAtCharIndex(int i, {bool trim = true}) {
    if (rp == null || trimmedSel.isCollapsed) return null;
    var offset = math.min(trimmedSel.end - 1, math.max(trimmedSel.start, i));

    // If trimming whitespace, skip whitespace.
    if (trim) {
      while (offset < trimmedSel.end && _shouldSkip(text.codeUnitAt(offset))) {
        offset++;
      }

      if (offset == trimmedSel.end) return null;
    }

    final range = rp!.getWordBoundary(TextPosition(offset: offset));
    return anchorAtRange(range, trim: trim);
  }

  /// Returns a new [SelectionAnchor] with the provided text [range].
  SelectionAnchor? anchorAtRange(TextRange? range, {bool trim = true}) {
    if (range != null) {
      final ts = createTextSelection(
        text,
        baseOffset: range.start,
        extentOffset: range.end,
        trim: trim,
      );
      if (ts != null && ts.isValid && (!trim || !ts.isCollapsed)) {
        final rects = rectsForSelection(ts);
        if (rects.isNotEmpty) {
          return SelectionAnchor(
            paragraphIndex,
            firstCharIndex,
            ts,
            rects,
            rp!.textDirection,
          );
        }
      } else {
        // dmPrint('Word not found, invalid text selection: '
        //     '$ts, with text range: $range, in string "$text"');
      }
    }
    return null;
  }

  /// Returns the list of [Rect]s for the [selection].
  List<Rect> rectsForSelection(TextSelection selection) {
    if (rp == null) return [];
    final textBoxes = rp!.getBoxesForSelection(selection);
    if (textBoxes.isNotEmpty) {
      return textBoxes
          .map((r) => r.toRect().translate(rect.left, rect.top))
          .toList();
    }
    return [];
  }

  /// Returns the [TextRange] for the text at the provided [Offset].
  TextRange? wordBoundaryAtPt(Offset pt, {bool onlyIfInRect = true}) {
    assert(rp != null);

    if (rp != null && (!onlyIfInRect || rect.contains(pt))) {
      // Get the text position closest to the provided [Offset].
      final textPosition = rp!.getPositionForOffset(_toLocalPt(pt));

      // If the `pt` is on the right side of the last letter of a word,
      // `getPositionForOffset` returns the position AFTER the word, so
      // we subtract 1 from the position to counteract that.
      //
      // Note, word boundary ranges are clamped to the length of [text]
      // because they can extend into clipped hidden trailing text, which
      // [from] excludes from [text].
      final range = _clampedToTextLength(
        rp!.getWordBoundary(
          textPosition.offset == 0
              ? textPosition
              : TextPosition(offset: textPosition.offset - 1),
        ),
      );
      if (range.start >= 0 && range.end > range.start) {
        // If the `pt` is on the left side of the first letter of a word,
        // the range will be of the whitespace or punctuation before the
        // word, so check for that...
        if (textPosition.offset > 0 && _isNonWordRange(range)) {
          final next = _clampedToTextLength(rp!.getWordBoundary(textPosition));
          if (!_isNonWordRange(next)) {
            return next;
          }
          // Otherwise, `next` is still non-word, which happens when the
          // position has upstream affinity (e.g. it was clamped to the end
          // of a line). If the range is visible punctuation (e.g. a closing
          // quote at the end of a paragraph), select it; if it is invisible
          // whitespace, select the word before it.
          if (!_isWhitespaceRange(range)) {
            return range;
          }
          if (range.start > 0) {
            return _clampedToTextLength(
              rp!.getWordBoundary(TextPosition(offset: range.start - 1)),
            );
          }
        }
        return range;
      } else {
        // dmPrint('Word not found, invalid text range: $range');
      }
    }
    return null;
  }

  /// Returns `true` if [range] is non-empty and contains only non-word
  /// characters (whitespace, punctuation, and quotes).
  bool _isNonWordRange(TextRange range) {
    for (var i = range.start; i < range.end; i++) {
      if (!text.isNonWordCharacterAtIndex(i)) return false;
    }
    return range.end > range.start;
  }

  /// Returns `true` if [range] is non-empty and contains only whitespace
  /// characters.
  bool _isWhitespaceRange(TextRange range) {
    for (var i = range.start; i < range.end; i++) {
      if (!text.isWhitespaceAtIndex(i)) return false;
    }
    return range.end > range.start;
  }

  /// Returns the given [range] clamped to the length of [text], which
  /// excludes clipped hidden trailing text, if any.
  TextRange _clampedToTextLength(TextRange range) => range.end <= text.length
      ? range
      : TextRange(start: math.min(range.start, text.length), end: text.length);

  /// Walks this paragraph's `InlineSpan` and its descendants in pre-order and
  /// calls [visitor] for each span that has text.
  ///
  /// When [visitor] returns `true`, the walk will continue. When [visitor]
  /// returns `false`, then the walk will end.
  ///
  /// Note, spans at or past the end of [text] (i.e. spans of clipped hidden
  /// trailing text, which [from] excludes from [text]) are skipped, without
  /// ending the walk.
  bool visitChildSpans(InlineSpanVisitorWithIndex visitor) {
    try {
      return rp!.text.visitChildrenEx(
        (span, index) => index >= text.length || visitor(span, index),
      );
    } catch (e) {
      dmPrint('Error in SelectionParagraph.visitChildSpans(): $e');
      return true;
    }
  }

  Offset _toLocalPt(Offset pt) => Offset(pt.dx - rect.left, pt.dy - rect.top);
}

extension SelectableExtOnObject on Object {
  /// If this is a RenderParagraph returns `this`, otherwise returns null.
  RenderParagraph? asRenderParagraph() =>
      this is RenderParagraph ? this as RenderParagraph : null;
}

/// Returns a new TextSelection, trimming whitespace characters if specified.
///
/// Returns null if the resulting string would be empty.
TextSelection? createTextSelection(
  String str, {
  int? baseOffset,
  int? extentOffset,
  bool trim = true,
}) {
  if (str.isEmpty) return null;
  final len = str.length;
  var first = baseOffset ?? 0;
  var last = extentOffset != null ? math.min(extentOffset, len) - 1 : len - 1;
  if (trim) {
    while (first < len && _shouldSkip(str.codeUnitAt(first))) {
      first++;
    }
    while (last > first && _shouldSkip(str.codeUnitAt(last))) {
      last--;
    }
  }
  if (last < first) return null;
  return TextSelection(baseOffset: first, extentOffset: last + 1);
}

extension SelectableExtOnListOfSelectionParagraph on List<SelectionParagraph> {
  /// Returns the index of the paragraph that contains [charIndex], or -1 if
  /// none do.
  int indexOfParagraphWithCharIndex(int charIndex) =>
      binarySearchWithCompare((e) {
        if (charIndex < e.firstCharIndex) return 1;
        if (charIndex >= e.firstCharIndex + e.text.length) return -1;
        return 0;
      });

  SelectionAnchor? updateAnchor(SelectionAnchor anchor) {
    // Uses char index at the middle of the word to better handle slight
    // changes in word position.
    final globalCharIndex =
        anchor.firstCharIndex +
        ((anchor.textSel.start + anchor.textSel.end) / 2).floor();
    final paraIndex = indexOfParagraphWithCharIndex(globalCharIndex);
    if (paraIndex >= 0) {
      final paragraph = this[paraIndex];
      return paragraph.anchorAtCharIndex(
        globalCharIndex - paragraph.firstCharIndex,
      );
    }
    return null;
  }
}

//
// MARK: Private
//

bool _shouldSkip(int rune) {
  return rune == objectReplacementCharacterCode || isWhitespaceCharacter(rune);
}

/// Returns the index of the first character in [rp]'s text that is rendered
/// entirely at or below [height] (i.e. the first clipped hidden character),
/// or [textLength] if there is none.
int _indexOfFirstClippedCharacter(
  RenderParagraph rp,
  double height,
  int textLength,
) {
  // A character's line top is non-decreasing with its index, so binary
  // search for the first character whose line top is at or below [height].
  var low = 0;
  var high = textLength;
  while (low < high) {
    final mid = (low + high) ~/ 2;
    final dy = rp.getOffsetForCaret(TextPosition(offset: mid), Rect.zero).dy;
    if (dy >= height - precisionErrorTolerance) {
      high = mid;
    } else {
      low = mid + 1;
    }
  }
  return low;
}
