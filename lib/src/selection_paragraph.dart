// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

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

  final RenderParagraph? rp;
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
    // In case this is called from non-null-safe code.
    // ignore: unnecessary_null_comparison
    assert(rp != null && ancestor != null);
    // In case this is called from non-null-safe code.
    // ignore: unnecessary_null_comparison
    assert(paragraphIndex != null && firstCharIndex != null);

    if (!rp.hasSize) return null;

    try {
      final span = rp.text;
      if (span is TextSpan) {
        final text = span.toPlainText(
            includeSemanticsLabels: false, includePlaceholders: true);
        final trimmedSel = createTextSelection(text);
        if (trimmedSel != null) {
          final offset = rp.getTransformTo(ancestor).getTranslation();
          final size = rp.textSize;
          final rect =
              Rect.fromLTWH(offset.x, offset.y, size.width, size.height);
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
      if (ts != null && ts.isValid && (!trim || !ts.isCollapsed)) {
        final rects = rectsForSelection(ts);
        if (rects.isNotEmpty) {
          return SelectionAnchor(
              paragraphIndex, firstCharIndex, ts, rects, rp!.textDirection);
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
    // In case this is called from non-null-safe code.
    // ignore: unnecessary_null_comparison
    assert(selection != null && rp != null);
    // In case this is called from non-null-safe code.
    // ignore: unnecessary_null_comparison
    if (selection != null) {
      final textBoxes = rp!.getBoxesForSelection(selection);
      if (textBoxes.isNotEmpty) {
        return textBoxes
            .map((r) => r.toRect().translate(rect.left, rect.top))
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
  /// If this is a RenderParagraph returns `this`, otherwise returns null.
  @Deprecated(
    'Replace `.asRenderText()` with `.asRenderParagraph()`. '
    'This was deprecated after selectable version 0.4.0',
  )
  RenderParagraph? asRenderText() => asRenderParagraph();

  /// If this is a RenderParagraph returns `this`, otherwise returns null.
  RenderParagraph? asRenderParagraph() =>
      this is RenderParagraph ? this as RenderParagraph : null;
}

extension SelectableExtOnRenderParagraph on RenderParagraph {
  @Deprecated(
    'Just delete the `.renderBox`. RenderParagraph is a RenderBox. '
    'This was deprecated after selectable version 0.4.0',
  )
  RenderBox get renderBox => this;

  @Deprecated(
    'Replace `.offset` with `Offset.zero`. '
    'This was deprecated after selectable version 0.4.0',
  )
  Offset get offset => Offset.zero;
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
  // In case this is called from non-null-safe code.
  // ignore: unnecessary_null_comparison
  assert(str != null);
  // In case this is called from non-null-safe code.
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
  return rune == objectReplacementCharacterCode || isWhitespaceCharacter(rune);
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
