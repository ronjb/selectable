import 'dart:ui' as ui show PlaceholderAlignment;

import 'package:flutter/widgets.dart';

///
/// An immutable widget that is embedded inline within text and is tagged.
///
/// The [child] property is the widget that will be embedded. Children are
/// constrained by the width of the paragraph.
///
/// The [child] property may contain its own [Widget] children (if applicable),
/// including [Text] and [RichText] widgets which may include additional
/// [WidgetSpan]s. Child [Text] and [RichText] widgets will be laid out
/// independently and occupy a rectangular space in the parent text layout.
///
@immutable
class TaggedWidgetSpan extends WidgetSpan {
  final Object tag;

  ///
  /// Creates a [TaggedWidgetSpan] with the given values.
  ///
  /// The [child] property must be non-null. [WidgetSpan] is a leaf node in
  /// the [InlineSpan] tree. Child widgets are constrained by the width of the
  /// paragraph they occupy. Child widget heights are unconstrained, and may
  /// cause the text to overflow and be ellipsized/truncated.
  ///
  /// A [TextStyle] may be provided with the [style] property, but only the
  /// decoration, foreground, background, and spacing options will be used.
  ///
  const TaggedWidgetSpan({
    required this.tag,
    required Widget child,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    TextBaseline? baseline,
    TextStyle? style,
  })  : assert(tag != null), // ignore: unnecessary_null_comparison
        assert(child != null), // ignore: unnecessary_null_comparison
        super(
          child: child,
          alignment: alignment,
          baseline: baseline,
          style: style,
        );

  ///
  /// Returns a copy of the TaggedWidgetSpan with optional changes.
  ///
  TaggedWidgetSpan copyWith({
    Object? tag,
    Widget? child,
    ui.PlaceholderAlignment? alignment,
    TextBaseline? baseline,
    TextStyle? style,
    double? childWidth,
  }) {
    return TaggedWidgetSpan(
      tag: tag ?? this.tag,
      child: child ?? this.child,
      alignment: alignment ?? this.alignment,
      baseline: baseline ?? this.baseline,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (super != other) return false;
    return other is TaggedWidgetSpan &&
        other.child == child &&
        other.alignment == alignment &&
        other.baseline == baseline &&
        other.tag == tag;
  }

  @override
  int get hashCode => hashValues(super.hashCode, tag);
}
