// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tagged_text.dart';
import 'tagged_text_span.dart';
import 'tagged_widget_span.dart';

/// Called on each span as `InlineSpan.visitChildrenEx` walks the `InlineSpan`
/// tree.
///
/// Return `true` to continue, or `false` to stop visiting further spans.
typedef InlineSpanVisitorWithIndex = bool Function(InlineSpan span, int index);

extension SelectableExtOnInlineSpan on InlineSpan {
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
  TaggedText? taggedTextForIndex(
    int index, {
    bool includesPlaceholders = true,
    bool end = false,
  }) {
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
  InlineSpan? spanWithCharacterAtIndex(
    int index, {
    bool includesPlaceholders = true,
  }) {
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

  /// Walks this [InlineSpan] and its descendants in pre-order and calls
  /// [visitor] for each span that has text.
  ///
  /// When [visitor] returns true, the walk will continue. When [visitor]
  /// returns false, then the walk will end.
  bool visitChildrenEx(
    InlineSpanVisitorWithIndex visitor, {
    bool includesPlaceholders = true,
  }) =>
      _visitChildrenEx(_Index(0), visitor);

  bool _visitChildrenEx(
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
          if (!child._visitChildrenEx(index, visitor,
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

/// Mutable wrapper of an integer that can be passed by reference to track a
/// value across a recursive stack.
class _Index {
  _Index(this.value);

  int value = 0;
}
