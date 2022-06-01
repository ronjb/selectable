// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A widget that detects pan gestures using [SelectablePanGestureRecognizer],
/// which is designed to work well even in scrollable parent widgets.
///
/// If this widget has a child, it defers to that child for its sizing behavior.
/// If it does not have a child, it grows to fit the parent instead.
///
/// By default a GestureDetector with an invisible child ignores touches;
/// this behavior can be controlled with [behavior].
///
/// GestureDetector also listens for accessibility events and maps
/// them to the callbacks. To ignore accessibility events, set
/// [excludeFromSemantics] to true.
///
/// See <http://flutter.dev/gestures/> for additional information.
///
/// ## Debugging
///
/// To see how large the hit test box of a [SelectablePanGestureDetector] is for
/// debugging purposes, set `debugPaintPointersEnabled` to true.
@immutable
class SelectablePanGestureDetector extends StatelessWidget {
  /// Creates a widget that detects pan gestures.
  ///
  /// By default, gesture detectors contribute semantic information to the tree
  /// that is used by assistive technology.
  const SelectablePanGestureDetector({
    super.key,
    this.child,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.behavior,
    this.excludeFromSemantics = false,
    this.dragStartBehavior = DragStartBehavior.start,
  })  :
        // ignore: unnecessary_null_comparison
        assert(excludeFromSemantics != null),
        // ignore: unnecessary_null_comparison
        assert(dragStartBehavior != null);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget? child;

  /// A pointer has contacted the screen with a primary button and might begin
  /// to move.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  final GestureDragDownCallback? onPanDown;

  /// A pointer has contacted the screen with a primary button and has begun to
  /// move.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  final GestureDragStartCallback? onPanStart;

  /// A pointer that is in contact with the screen with a primary button and
  /// moving has moved again.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  final GestureDragUpdateCallback? onPanUpdate;

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  final GestureDragEndCallback? onPanEnd;

  /// The pointer that previously triggered [onPanDown] did not complete.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  final GestureDragCancelCallback? onPanCancel;

  /// How this gesture detector should behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.deferToChild] if [child] is not null and
  /// [HitTestBehavior.translucent] if child is null.
  final HitTestBehavior? behavior;

  /// Whether to exclude these gestures from the semantics tree. For
  /// example, the long-press gesture for showing a tooltip is
  /// excluded because the tooltip itself is included in the semantics
  /// tree directly and so having a gesture to show it would result in
  /// duplication of information.
  final bool excludeFromSemantics;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], gesture drag behavior will
  /// begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first
  /// detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// Only the [onPanStart] callbacks for the [VerticalDragGestureRecognizer],
  /// [HorizontalDragGestureRecognizer] and [PanGestureRecognizer] are affected
  /// by this setting.
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for
  ///  the different behaviors.
  final DragStartBehavior dragStartBehavior;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        SelectablePanGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            SelectablePanGestureRecognizer>(
          SelectablePanGestureRecognizer.new,
          (instance) {
            instance
              ..onDown = onPanDown
              ..onStart = onPanStart
              ..onUpdate = onPanUpdate
              ..onEnd = onPanEnd
              ..onCancel = onPanCancel
              ..dragStartBehavior = dragStartBehavior;
          },
        ),
      },
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        EnumProperty<DragStartBehavior>('startBehavior', dragStartBehavior));
  }
}

///
/// SelectablePanGestureRecognizer
///
class SelectablePanGestureRecognizer extends PanGestureRecognizer {
  /// Create a gesture recognizer for tracking movement on a plane.
  SelectablePanGestureRecognizer({super.debugOwner}) {
    onDown = _onDown;
  }

  @override
  set onDown(GestureDragDownCallback? func) {
    super.onDown = (details) {
      _onDown(details);
      if (func != null) func(details);
    };
  }

  void _onDown(DragDownDetails details) {
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'SelectablePanGestureRecognizer';
}
