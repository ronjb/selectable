// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui' as ui show Locale;

import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Mixin for tag classes that support being split along with the text span
/// they are tagging.
mixin SplittableTextSpanTag<T> {
  List<T> splitWith(TextSpan span, {required int atCharacter});
}

/// [TaggedTextSpan] extends [TextSpan] to include a [tag] object and
/// the ability to be split at a provided index. Other than that it is
/// functionally equivalent to [TextSpan].
@immutable
class TaggedTextSpan extends TextSpan with SplittableMixin<InlineSpan> {
  /// Creates a [TaggedTextSpan] with the provided properties.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  const TaggedTextSpan({
    required this.tag,
    super.text,
    super.children,
    super.style,
    super.recognizer,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
    super.semanticsLabel,
    super.locale,
    super.spellOut,
  }) :
        // ignore: unnecessary_null_comparison
        assert(tag != null);

  /// The tag object.
  final Object tag;

  /// Returns a copy of the TaggedTextSpan with optional changes.
  TaggedTextSpan ttsCopyWith({
    Object? tag,
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
    GestureRecognizer? recognizer,
    MouseCursor? mouseCursor,
    PointerEnterEventListener? onEnter,
    PointerExitEventListener? onExit,
    String? semanticsLabel,
    ui.Locale? locale,
    bool? spellOut,
    bool noText = false,
    bool noChildren = false,
  }) {
    // print('returning copy of TaggedTextSpan...');
    return TaggedTextSpan(
      tag: tag ?? this.tag,
      text: text ?? (noText ? null : this.text),
      children: children ?? (noChildren ? null : this.children),
      style: style ?? this.style,
      recognizer: recognizer ?? this.recognizer,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      onEnter: onEnter ?? this.onEnter,
      onExit: onExit ?? this.onExit,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      locale: locale ?? this.locale,
      spellOut: spellOut ?? this.spellOut,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (super != other) return false;
    return other is TaggedTextSpan &&
        other.text == text &&
        other.recognizer == recognizer &&
        other.semanticsLabel == semanticsLabel &&
        onEnter == other.onEnter &&
        onExit == other.onExit &&
        mouseCursor == other.mouseCursor &&
        other.tag == tag &&
        listEquals<InlineSpan>(other.children, children);
  }

  @override
  int get hashCode => Object.hash(super.hashCode, tag);

  //
  // SplittableMixin related:
  //

  @override
  List<InlineSpan> splitAtIndex(
    SplitAtIndex index, {
    bool ignoreFloatedWidgetSpans = false,
  }) {
    final initialIndex = index.value;
    final result = defaultSplitSpanAtIndex(
      index,
      ignoreFloatedWidgetSpans: ignoreFloatedWidgetSpans,
      copyWithTextSpan: (span, text, children) => span is TaggedTextSpan
          ? span.ttsCopyWith(
              text: text,
              children: children,
              noText: text == null,
              noChildren: children == null)
          : span.copyWith(
              text: text,
              children: children,
              noText: text == null,
              noChildren: children == null),
    );

    // If this span was split, and its tag is splittable, split the tag too.
    if (result.length == 2 && tag is SplittableTextSpanTag) {
      assert(result.first is TaggedTextSpan && result.last is TaggedTextSpan);
      final splitTags = (tag as SplittableTextSpanTag)
          .splitWith(this, atCharacter: initialIndex);
      assert(splitTags.length == 2);
      result[0] =
          (result[0] as TaggedTextSpan).ttsCopyWith(tag: splitTags.first);
      result[1] =
          (result[1] as TaggedTextSpan).ttsCopyWith(tag: splitTags.last);
    }

    return result;
  }
}
