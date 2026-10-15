// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that makes the text in the `WidgetSpan` containing it part of the
/// paragraph containing the `WidgetSpan`, for selection via its `Selectable`
/// ancestor widget.
///
/// Flutter can only raise or lower text, e.g. a superscript or subscript, by
/// drawing it in a `WidgetSpan`. Otherwise, the text in a `WidgetSpan` is a
/// paragraph of its own, which is selected apart from the paragraph containing
/// the `WidgetSpan` and is copied after it. With an [InlineSelectable]
/// anywhere in the `WidgetSpan`'s widget, the text in the widget is copied and
/// highlighted where it is drawn:
///
/// ```dart
/// WidgetSpan(
///   alignment: PlaceholderAlignment.baseline,
///   baseline: TextBaseline.alphabetic,
///   child: Transform.translate(
///     offset: const Offset(0, -6),
///     child: const InlineSelectable(child: Text('5')),
///   ),
/// )
/// ```
///
/// The text in the widget is selected as a unit, like a character of the
/// paragraph, so it is meant for short text. Outside a `WidgetSpan`, an
/// [InlineSelectable] has no effect.
class InlineSelectable extends SingleChildRenderObjectWidget {
  /// Creates a widget that makes the text in the `WidgetSpan` containing it
  /// part of the paragraph containing the `WidgetSpan`.
  const InlineSelectable({super.key, super.child});

  @override
  RenderInlineSelectable createRenderObject(BuildContext context) =>
      RenderInlineSelectable();
}

/// The render object of an [InlineSelectable].
class RenderInlineSelectable extends RenderProxyBox {}
