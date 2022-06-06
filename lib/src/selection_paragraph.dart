// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

import 'package:float_column/float_column.dart';
import 'package:flutter/rendering.dart';

import 'common.dart';
import 'inline_span_ext.dart';
import 'selection_anchor.dart';
import 'string_utils.dart';
import 'tagged_text.dart';
import 'tagged_text_span.dart';
import 'tagged_widget_span.dart';

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

  final RenderTextMixin? rp;
  final Rect rect;
  final String text;
  final TextSelection trimmedSel;
  final int paragraphIndex;
  final int firstCharIndex;

  @override
  int compareTo(SelectionParagraph? other) {
    var v = (other == null ? 1 : 0);
    if (v == 0) v = paragraphIndex - other!.paragraphIndex;
    if (v == 0) v = firstCharIndex - other!.firstCharIndex;
    return v;
  }

  /// Returns a new `SelectionParagraph` or `null` if the provided
  /// `RenderTextMixin` has no size (i.e. has not undergone layout),
  /// or if its `text` is empty or just whitespace.
  ///
  /// The [ancestor] must be an ancestor of the provided `RenderTextMixin`,
  /// and is used to determine the offset of this paragraph's rect.
  static SelectionParagraph? from(
    RenderTextMixin rp, {
    required RenderObject ancestor,
    int paragraphIndex = 0,
    int firstCharIndex = 0,
  }) {
    // ignore: unnecessary_null_comparison
    assert(rp != null && ancestor != null);
    // ignore: unnecessary_null_comparison
    assert(paragraphIndex != null && firstCharIndex != null);

    if (!rp.renderBox.hasSize) return null;

    try {
      final span = rp.text;
      if (span is TextSpan) {
        final text = span.toPlainText(
            includeSemanticsLabels: false, includePlaceholders: true);
        final trimmedSel = createTextSelection(text);
        if (trimmedSel != null) {
          final offset = rp.renderBox.getTransformTo(ancestor).getTranslation();
          final size = rp.textSize;
          final rect = Rect.fromLTWH(offset.x + rp.offset.dx,
              offset.y + rp.offset.dy, size.width, size.height);
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
    RenderTextMixin? rp,
    Rect? rect,
    String? text,
    TextSelection? trimmedSel,
    int? paragraphIndex,
    int? firstCharIndex,
  }) =>
      SelectionParagraph(
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
    return anchorAtRange(wordBoundaryAtPt(pt, onlyIfInRect: onlyIfInRect),
        trim: trim);
  }

  /// Returns a new [SelectionAnchor] at the provided character index.
  SelectionAnchor? anchorAtCharIndex(
    int i, {
    bool trim = true,
  }) {
    assert(rp != null);
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
  SelectionAnchor? anchorAtRange(
    TextRange? range, {
    bool trim = true,
  }) {
    if (range != null) {
      final ts = createTextSelection(text,
          baseOffset: range.start, extentOffset: range.end, trim: trim);
      if (ts != null && ts.isValid && (trim == false || !ts.isCollapsed)) {
        final rects = rectsForSelection(ts);
        if (rects.isNotEmpty) {
          return SelectionAnchor(paragraphIndex, firstCharIndex, ts, rects);
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
    // ignore: unnecessary_null_comparison
    assert(selection != null && rp != null);
    // ignore: unnecessary_null_comparison
    if (selection != null) {
      final textBoxes = rp!.getBoxesForSelection(selection);
      if (textBoxes.isNotEmpty) {
        return textBoxes
            .mergedToSelectionRects()
            .map((r) => r.translate(rect.left, rect.top))
            .toList();
      } else {
        // dmPrint('getBoxesForSelection($selection) returned no boxes in '
        //     'string "$text"');
      }
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
      final range = rp!.getWordBoundary(textPosition.offset == 0
          ? textPosition
          : TextPosition(offset: textPosition.offset - 1));
      if (range.start >= 0 && range.end > range.start) {
        // If the `pt` is on the left side of the first letter of a word,
        // the range will be of the whitespace before the word, so check
        // for that...
        if (textPosition.offset > 0 &&
            range.end == range.start + 1 &&
            text.isWhitespaceAtIndex(range.start)) {
          return rp!.getWordBoundary(textPosition);
        }
        return range;
      } else {
        // dmPrint('Word not found, invalid text range: $range');
      }
    }
    return null;
  }

  /// Walks this paragraph's `InlineSpan` and its descendants in pre-order and
  /// calls [visitor] for each span that has text.
  ///
  /// When [visitor] returns `true`, the walk will continue. When [visitor]
  /// returns `false`, then the walk will end.
  bool visitChildSpans(InlineSpanVisitorWithIndex visitor) =>
      rp!.text.visitChildrenEx(visitor);

  Offset _toLocalPt(Offset pt) => Offset(pt.dx - rect.left, pt.dy - rect.top);

  /// Returns the [TextRange] of the word after [range].
  // TextRange wordRangeAfter(TextRange range) {
  //   assert(rp != null);
  //   if (range == null || range.end >= trimmedSel.end) return null;
  //   var i = range.end;
  //   while (i < trimmedSel.end && _shouldSkip(text.codeUnitAt(i))) {
  //     i++;
  //   }
  //   if (i >= trimmedSel.end) return null;
  //   return rp.getWordBoundary(TextPosition(offset: i)); // + 1));
  // }
}

extension SelectableExtOnObject on Object {
  /// Returns a RenderTextMixin for this object if it is a RenderParagraph or
  /// implements the RenderTextMixin, otherwise returns null.
  RenderTextMixin? asRenderText() => this is RenderParagraph
      ? RenderParagraphAdapter(this as RenderParagraph)
      : this is RenderTextMixin
          ? this as RenderTextMixin
          : null;
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
  // ignore: unnecessary_null_comparison
  assert(str != null);
  // ignore: unnecessary_null_comparison
  if (str == null || str.isEmpty) return null;
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
    final globalCharIndex = anchor.firstCharIndex +
        ((anchor.textSel.start + anchor.textSel.end) / 2).floor();
    final paraIndex = indexOfParagraphWithCharIndex(globalCharIndex);
    if (paraIndex >= 0) {
      final paragraph = this[paraIndex];
      return paragraph
          .anchorAtCharIndex(globalCharIndex - paragraph.firstCharIndex);
    }
    return null;
  }
}

//
// PRIVATE
//

bool _shouldSkip(int rune) {
  return rune == objectReplacementCharacterCode || isWhitespaceRune(rune);
}

///
/// Returns an iterable list of tags in the [span] or an empty list if none.
///
// ignore: unused_element
Iterable<Object> _tagsFromSpan(InlineSpan span) {
  if (span is TaggedTextSpan) return [span.tag];
  if (span is TaggedWidgetSpan) return [span.tag];
  if (span is TextSpan && (span.children?.isNotEmpty ?? false)) {
    return span.children!.expand<Object>(_tagsFromSpan);
  }
  return [];
}
