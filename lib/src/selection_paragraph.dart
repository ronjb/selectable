// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'common.dart';
import 'tagged_text.dart';
import 'tagged_text_span.dart';
import 'tagged_widget_span.dart';

///
/// The render paragraph index and text selection for the left or right anchor.
///
@immutable
class SelectionAnchor extends Equatable implements Comparable<SelectionAnchor> {
  final int paragraph;
  final TextSelection textSel;
  final List<Rect> rects;

  const SelectionAnchor(this.paragraph, this.textSel, this.rects)
      :
        // ignore: unnecessary_null_comparison
        assert(paragraph != null && textSel != null && rects != null),
        assert(paragraph >= 0);

  SelectionAnchor copyInflated(double delta) => SelectionAnchor(
        paragraph,
        textSel,
        rects.map((rect) => rect.inflate(delta)).toList(),
      );

  bool containsPoint(Offset? point) => rects.containsPoint(point);

  bool operator <(SelectionAnchor? other) => (compareTo(other) < 0);
  bool operator <=(SelectionAnchor? other) => (compareTo(other) <= 0);
  bool operator >(SelectionAnchor? other) => (compareTo(other) > 0);
  bool operator >=(SelectionAnchor? other) => (compareTo(other) >= 0);

  @override
  int compareTo(SelectionAnchor? other) {
    var v = (other == null ? 1 : 0);
    if (v == 0) v = paragraph - other!.paragraph;
    if (v == 0) v = textSel.start - other!.textSel.start;
    if (v == 0) v = textSel.end - other!.textSel.end;
    return v;
  }

  @override
  List<Object?> get props => [paragraph, textSel.start, textSel.end];

  ///
  /// Creates and returns the [TaggedText] object for this anchor.
  ///
  TaggedText? taggedTextWithParagraphs(List<SelectionParagraph> paragraphs,
      {bool end = false}) {
    TaggedText? taggedText;
    if (paragraphs.length > paragraph) {
      taggedText = paragraphs[paragraph]
          .rp
          ?.text
          .taggedTextForIndex(end ? textSel.end : textSel.start, end: end);
    }
    if (taggedText == null) {
      // dmPrint('ERROR: Selectable '
      //     'taggedTextForIndex(${end ? textSel.end : textSel.start},'
      //     ' end: ${end ? 'true' : 'false'}) failed for string: '
      //     '${paragraphs[paragraph].rp?.text}');
      assert(false);
    }
    return taggedText;
  }
}

///
/// Render paragraph data.
///
class SelectionParagraph {
  final RenderTextMixin? rp;
  final Rect rect;
  final int index;
  final String text;
  final TextSelection trimmedSel;

  const SelectionParagraph({
    required this.rp,
    required this.rect,
    required this.index,
    required this.text,
    required this.trimmedSel,
  });

  ///
  /// Returns a new `SelectionParagraph` or `null` if the given
  /// `RenderTextMixin` has no size (i.e. has not undergone layout), or if
  /// its `text` is empty or just whitespace.
  ///
  /// [ancestor] must be an ancestor of the given `RenderTextMixin`, and is
  /// used to determine the offset of this paragraph's rect.
  ///
  static SelectionParagraph? from(
    RenderTextMixin rp, {
    required RenderObject ancestor,
    int index = 0,
  }) {
    // ignore: unnecessary_null_comparison
    assert(rp != null && ancestor != null && index != null);

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
              index: index,
              text: text,
              trimmedSel: trimmedSel);
        }
      }
    } catch (e) {
      // dmPrint('ERROR: In Selectable, SelectionParagraph.from(): $e');
    }

    return null;
  }

  ///
  /// Returns a copy of this paragraph with zero or more property values
  /// updated.
  ///
  SelectionParagraph copyWith({
    RenderTextMixin? rp,
    Rect? rect,
    int? index,
    String? text,
    TextSelection? trimmedSel,
  }) =>
      SelectionParagraph(
        rp: rp ?? this.rp,
        rect: rect ?? this.rect,
        index: index ?? this.index,
        text: text ?? this.text,
        trimmedSel: trimmedSel ?? this.trimmedSel,
      );

  ///
  /// Returns a new `SelectionAnchor` at the given `Offset`.
  ///
  SelectionAnchor? anchorAtPt(
    Offset pt, {
    bool onlyIfInRect = true,
    bool trim = true,
  }) {
    return anchorAtRange(wordBoundaryAtPt(pt, onlyIfInRect: onlyIfInRect),
        trim: trim);
  }

  ///
  /// Returns a new `SelectionAnchor` at the given character index.
  ///
  SelectionAnchor? anchorAtCharIndex(
    int i, {
    bool trim = true,
  }) {
    assert(rp != null);
    final offset = math.min(trimmedSel.end - 1, math.max(trimmedSel.start, i));
    final range = rp!.getWordBoundary(TextPosition(offset: offset));
    return anchorAtRange(range, trim: trim);
  }

  ///
  /// Returns a new `SelectionAnchor` with the given text [range].
  ///
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
          return SelectionAnchor(index, ts, rects);
        }
      } else {
        // dmPrint('Word not found, invalid text selection: '
        //     '$ts, with text range: $range, in string "$text"');
      }
    }
    return null;
  }

  ///
  /// Returns the list of `Rect`s for the given [selection].
  ///
  List<Rect> rectsForSelection(TextSelection selection) {
    assert(
        selection != null && rp != null); // ignore: unnecessary_null_comparison
    // ignore: unnecessary_null_comparison
    if (selection != null) {
      final boxes = rp!.getBoxesForSelection(selection);
      if (boxes.isNotEmpty) {
        return boxes
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

  ///
  /// Returns the [TextRange] for the text at the given offset.
  ///
  TextRange? wordBoundaryAtPt(Offset pt, {bool onlyIfInRect = true}) {
    assert(rp != null);

    if (rp != null && (!onlyIfInRect || rect.contains(pt))) {
      // Get the text position closest to the given offset.
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
            _isWhitespace(
                text.substring(range.start, range.end).codeUnitAt(0))) {
          return rp!.getWordBoundary(textPosition);
        }
        return range;
      } else {
        //dmPrint('Word not found, invalid text range: $range');
      }
    }
    return null;
  }

  ///
  /// Walks this paragraph's `InlineSpan` and its descendants in pre-order and
  /// calls [visitor] for each span that has text.
  ///
  /// When [visitor] returns true, the walk will continue. When [visitor]
  /// returns false, then the walk will end.
  ///
  bool visitChildSpans(InlineSpanVisitorWithIndex visitor) =>
      rp!.text.visitChildrenEx(_Index(0), visitor);

  Offset _toLocalPt(Offset pt) => Offset(pt.dx - rect.left, pt.dy - rect.top);

  ///
  /// Returns the [TextRange] of the word after the given [range].
  ///
  // TextRange wordRangeAfter(TextRange range) {
  //   assert(rp != null);
  //   if (range == null || range.end >= trimmedSel.end) return null;
  //   var i = range.end;
  //   while (i < trimmedSel.end && _skip(text.codeUnitAt(i))) {
  //     i++;
  //   }
  //   if (i >= trimmedSel.end) return null;
  //   return rp.getWordBoundary(TextPosition(offset: i)); // + 1));
  // }
}

///
/// Returns a new TextSelection, trimming whitespace characters if specified.
///
/// Returns null if the resulting string would be empty.
///
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
    while (first < len && _skip(str.codeUnitAt(first))) {
      first++;
    }
    while (last > first && _skip(str.codeUnitAt(last))) {
      last--;
    }
  }
  if (last < first) return null;
  return TextSelection(baseOffset: first, extentOffset: last + 1);
}

//
// PRIVATE STUFF
//

bool _skip(int rune) {
  return rune == objectReplacementCharacterCode || _isWhitespace(rune);
}

///
/// Returns true iff the given character is a whitespace character.
///
/// Built by referencing the _isWhitespace functions in
/// https://api.flutter.dev/flutter/quiver.strings/isWhitespace.html
/// and
/// https://github.com/flutter/flutter/blob/master/packages/
/// flutter/lib/src/rendering/editable.dart
///
/// Tested using an if statement vs. a set.contains(), and using the set was
/// three times as fast!
///
/// For more info on unicode chars see http://www.unicode.org/charts/ or
/// https://www.compart.com/en/unicode/U+00A0
///
bool _isWhitespace(int rune) => _whitespace.contains(rune);

const _whitespace = <int>{
  0x0009, // [␉] horizontal tab
  0x000A, // [␊] line feed
  0x000B, // [␋] vertical tab
  0x000C, // [␌] form feed
  0x000D, // [␍] carriage return

  // Not sure we need to include these chars, so commented out for now.
  // 0x001C, // [␜] file separator
  // 0x001D, // [␝] group separator
  // 0x001E, // [␞] record separator
  // 0x001F, // [␟] unit separator

  0x0020, // [ ] space
  0x0085, // next line
  0x00A0, // [ ] no-break space
  0x1680, // [ ] ogham space mark
  0x2000, // [ ] en quad
  0x2001, // [ ] em quad
  0x2002, // [ ] en space
  0x2003, // [ ] em space
  0x2004, // [ ] three-per-em space
  0x2005, // [ ] four-per-em space
  0x2006, // [ ] six-per-em space
  0x2007, // [ ] figure space
  0x2008, // [ ] punctuation space
  0x2009, // [ ] thin space
  0x200A, // [ ] hair space
  0x202F, // [ ] narrow no-break space
  0x205F, // [ ] medium mathematical space
  0x3000, // [　] ideographic space
};

// ignore_for_file: unused_element

///
/// Returns an iterable list of tags in the given [span] or an empty list if
/// none.
///
Iterable<Object> _tagsFromSpan(InlineSpan span) {
  if (span is TaggedTextSpan) return [span.tag];
  if (span is TaggedWidgetSpan) return [span.tag];
  if (span is TextSpan && (span.children?.isNotEmpty ?? false)) {
    return span.children!.expand<Object>(_tagsFromSpan);
  }
  return [];
}

extension on InlineSpan {
  ///
  /// Searches this span and its contained spans (if any) for the span that
  /// contains the character at the given [index], and if found, returns a
  /// [TaggedText] object with `taggedText.tag` set to the containing span's
  /// `tag` property (or `null` if it is not tagged), `taggedText.text` set
  /// to the containing span's `text` value (or `String.fromCharCode(0xFFFC)`
  /// if the containing span is not a TextSpan and [includesPlaceholders] is
  /// true), and `taggedText.index` set to the index into `taggedText.text`
  /// of the character.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final includePlaceholders = true;
  /// final text = textSpan.toPlainText(
  ///   includeSemanticsLabels: false,
  ///   includePlaceholders: includePlaceholders,
  /// );
  /// final taggedText = textSpan.taggedTextForIndex(
  ///   42,
  ///   includesPlaceholders: includePlaceholders,
  /// );
  /// ```
  TaggedText? taggedTextForIndex(int index,
      {bool includesPlaceholders = true, bool end = false}) {
    // ignore: unnecessary_null_comparison
    assert(index != null && index >= 0);
    final idx = _Index(end ? math.max(0, index - 1) : index);
    final span =
        _spanWithIndex(idx, includesPlaceholders: includesPlaceholders);
    if (span != null) {
      return TaggedText(
        span is TaggedTextSpan
            ? span.tag
            : span is TaggedWidgetSpan
                ? span.tag
                : null,
        span is TextSpan
            ? span.text!
            : String.fromCharCode(objectReplacementCharacterCode),
        end ? idx.value + 1 : idx.value,
      );
    }
    return null;
  }

  ///
  /// Searches this span and its contained spans (if any) for the span that
  /// contains the character at the given [index], and if found, returns it.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// final includePlaceholders = true;
  /// final text = textSpan.toPlainText(
  ///   includeSemanticsLabels: false,
  ///   includePlaceholders: includePlaceholders,
  /// );
  /// final span = textSpan.spanWithCharacterAtIndex(
  ///   42,
  ///   includesPlaceholders: includePlaceholders,
  /// );
  /// ```
  InlineSpan? spanWithCharacterAtIndex(int index,
      {bool includesPlaceholders = true}) {
    return _spanWithIndex(_Index(index),
        includesPlaceholders: includesPlaceholders);
  }

  InlineSpan? _spanWithIndex(_Index index, {bool includesPlaceholders = true}) {
    final span = this;
    if (span is TextSpan) {
      if (span.text?.isNotEmpty ?? false) {
        final len = span.text!.length;
        if (index.value >= len) {
          index.value -= len;
        } else {
          return this;
        }
      }
      if (span.children != null) {
        for (final child in span.children!) {
          final inlineSpan = child._spanWithIndex(index,
              includesPlaceholders: includesPlaceholders);
          if (inlineSpan != null) return inlineSpan;
        }
      }
    } else if (includesPlaceholders) {
      if (index.value == 0) return this;
      index.value -= 1;
    }
    return null;
  }

  ///
  /// Walks this [InlineSpan] and its descendants in pre-order and calls
  /// [visitor] for each span that has text.
  ///
  /// When [visitor] returns true, the walk will continue. When [visitor]
  /// returns false, then the walk will end.
  ///
  bool visitChildrenEx(
    _Index index,
    InlineSpanVisitorWithIndex visitor, {
    bool includesPlaceholders = true,
  }) {
    final span = this;
    if (span is TextSpan) {
      if (span.text != null) {
        if (!visitor(this, index.value)) return false;
        index.value += span.text!.length;
      }
      if (span.children != null) {
        for (final child in span.children!) {
          if (!child.visitChildrenEx(index, visitor,
              includesPlaceholders: includesPlaceholders)) {
            return false;
          }
        }
      }
    } else {
      if (!visitor(this, index.value)) return false;
      index.value += includesPlaceholders ? 1 : 0;
    }
    return true;
  }
}

/// Called on each span as `InlineSpan.visitChildrenEx` walks the `InlineSpan`
/// tree.
///
/// Return `true` to continue, or `false` to stop visiting further [InlineSpan]s.
///
typedef InlineSpanVisitorWithIndex = bool Function(InlineSpan span, int index);

/// Mutable wrapper of an integer that can be passed by reference to track a
/// value across a recursive stack.
class _Index {
  int value = 0;
  _Index(this.value);
}
