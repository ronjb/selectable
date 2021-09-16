import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

///
/// Mixin for tag classes that should be split along with the text span they are tagging.
///
mixin SplittableTextSpanTag<T> {
  List<T> splitWith(TextSpan span, {required int atCharacter});
}

///
/// A tagged TextSpan.
///
@immutable
class TaggedTextSpan extends TextSpan with SplittableMixin<InlineSpan> {
  final Object tag;

  ///
  /// Creates a [TextSpan] with the given values.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  ///
  const TaggedTextSpan({
    required this.tag,
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
    GestureRecognizer? recognizer,
    String? semanticsLabel,
  })  : assert(tag != null), // ignore: unnecessary_null_comparison
        super(
          text: text,
          children: children,
          style: style,
          recognizer: recognizer,
          semanticsLabel: semanticsLabel,
        );

  ///
  /// Returns a copy of the TaggedTextSpan with optional changes.
  ///
  TaggedTextSpan copyWith({
    Object? tag,
    String? text,
    List<InlineSpan>? children,
    TextStyle? style,
    GestureRecognizer? recognizer,
    String? semanticsLabel,
    bool noText = false,
    bool noChildren = false,
  }) {
    return TaggedTextSpan(
      tag: tag ?? this.tag,
      text: noText ? null : (text ?? this.text),
      children: noChildren ? null : (children ?? this.children),
      style: style ?? this.style,
      recognizer: recognizer ?? this.recognizer,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
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
        other.tag == tag &&
        listEquals<InlineSpan>(other.children, children);
  }

  @override
  int get hashCode => hashValues(super.hashCode, tag);

  //
  // SplittableMixin related:
  //

  @override
  List<InlineSpan> splitAtIndex(SplitAtIndex index) {
    final initialIndex = index.value;
    final result = _splitAtIndex(index);

    // If this span was split, and its tag is splittable, split the tag too.
    if (result.length == 2 && tag is SplittableTextSpanTag) {
      assert(result.first is TaggedTextSpan && result.last is TaggedTextSpan);
      final splitTags = (tag as SplittableTextSpanTag).splitWith(this, atCharacter: initialIndex);
      assert(splitTags.length == 2);
      result[0] = (result[0] as TaggedTextSpan).copyWith(tag: splitTags.first);
      result[1] = (result[1] as TaggedTextSpan).copyWith(tag: splitTags.last);
    }

    return result;
  }

  List<InlineSpan> _splitAtIndex(SplitAtIndex index) {
    if (index.value == 0) return [this];
    if (index.value == 0) return [this];

    final span = this;
    if (span is TextSpan) {
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        if (index.value >= text.length) {
          index.value -= text.length;
        } else {
          final result = [
            span.copyWith(text: text.substring(0, index.value), noChildren: true),
            span.copyWith(text: text.substring(index.value)),
          ];
          index.value = 0;
          return result;
        }
      }

      final children = span.children;
      if (children != null && children.isNotEmpty) {
        // If the text.length was equal to index.value, split the text and children.
        if (index.value == 0) {
          return [
            span.copyWith(text: text, noChildren: true),
            span.copyWith(noText: true),
          ];
        }

        final result = children.splitAtCharacterIndex(index);

        if (index.value == 0) {
          if (result.length == 2) {
            return [
              span.copyWith(text: text, children: result.first),
              span.copyWith(noText: true, children: result.last),
            ];
          } else if (result.length == 1) {
            // Only true if the number of characters in all the children was equal to index.value.
            assert(listEquals<InlineSpan>(result.first, children));
          } else {
            assert(false);
          }
        }
      }
    } else if (span is WidgetSpan) {
      index.value -= 1;
    } else {
      assert(false);
    }

    return [this];
  }
}
