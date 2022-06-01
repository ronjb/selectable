// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'selection.dart';

// ignore_for_file: comment_references

/// [SelectionPainter]
///
/// To implement a custom painter, either subclass or implement this interface
/// to define your custom paint delegate. [SelectionPainter] subclasses must
/// implement the [paint] and [shouldRepaint] methods, and may optionally also
/// implement the [hitTest] method.
///
/// The [paint] method is called whenever the custom object needs to be
/// repainted.
///
/// The [shouldRepaint] method is called when a new instance of the class
/// is provided, to check if the new instance actually represents different
/// information.
///
/// The most efficient way to trigger a repaint is to either:
///
/// * Extend this class and supply a `repaint` argument to the constructor of
///   the [SelectionPainter], where that object notifies its listeners when it
///   is time to repaint.
/// * Extend [Listenable] (e.g. via [ChangeNotifier]) and implement
///   [SelectionPainter], so that the object itself provides the notifications
///   directly.
///
/// In either case, the [Selectable] widget or [RenderSelectable] render object
/// will listen to the [Listenable] and repaint whenever the animation ticks,
/// avoiding both the build and layout phases of the pipeline.
///
/// The [hitTest] method is called when the user interacts with the underlying
/// render object, to determine if the user hit the object or missed it.
///
abstract class SelectionPainter extends Listenable {
  /// Creates a custom painter.
  ///
  /// The painter will repaint whenever `repaint` notifies its listeners.
  const SelectionPainter({Listenable? repaint}) : _repaint = repaint;

  final Listenable? _repaint;

  /// Register a closure to be notified when it is time to repaint.
  ///
  /// The [SelectionPainter] implementation merely forwards to the same method
  /// on the [Listenable] provided to the constructor in the `repaint` argument,
  /// if it was not null.
  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies when it is time to repaint.
  ///
  /// The [SelectionPainter] implementation merely forwards to the same method
  /// on the [Listenable] provided to the constructor in the `repaint` argument,
  /// if it was not null.
  @override
  void removeListener(VoidCallback listener) =>
      _repaint?.removeListener(listener);

  /// Called whenever the object needs to paint. The given [Canvas] has its
  /// coordinate space configured such that the origin is at the top left of the
  /// box. The area of the box is the size of the [size] argument.
  ///
  /// Paint operations should remain inside the given area. Graphical
  /// operations outside the bounds may be silently ignored, clipped, or not
  /// clipped. It may sometimes be difficult to guarantee that a certain
  /// operation is inside the bounds (e.g., drawing a rectangle whose size is
  /// determined by user inputs). In that case, consider calling
  /// [Canvas.clipRect] at the beginning of [paint] so everything that follows
  /// will be guaranteed to only draw within the clipped area.
  ///
  /// Implementations should be wary of correctly pairing any calls to
  /// [Canvas.save]/[Canvas.saveLayer] and [Canvas.restore], otherwise all
  /// subsequent painting on this canvas may be affected, with potentially
  /// hilarious but confusing results.
  void paint(Canvas canvas, Size size, Selection selection);

  /// Called whenever a new instance of the custom painter delegate class is
  /// provided to the [RenderSelectable] object, or any time that a new
  /// [Selectable] object is created with a new instance of the custom painter
  /// delegate class (which amounts to the same thing, because the latter is
  /// implemented in terms of the former).
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If the method returns false, then the [paint] call might be optimized
  /// away.
  ///
  /// It's possible that the [paint] method will get called even if
  /// [shouldRepaint] returns false (e.g. if an ancestor or descendant needed to
  /// be repainted). It's also possible that the [paint] method will get called
  /// without [shouldRepaint] being called at all (e.g. if the box changes
  /// size).
  ///
  /// If a custom delegate has a particularly expensive paint function such that
  /// repaints should be avoided as much as possible, a [RepaintBoundary] or
  /// [RenderRepaintBoundary] (or other render object with
  /// [RenderObject.isRepaintBoundary] set to true) might be helpful.
  ///
  /// The `oldDelegate` argument will never be null.
  bool shouldRepaint(covariant SelectionPainter oldDelegate);

  /// Called whenever a hit test is being performed on an object that is using
  /// this custom paint delegate.
  ///
  /// The given point is relative to the same coordinate space as the last
  /// [paint] call.
  ///
  /// The default behavior is to consider all points to be hits for
  /// background painters, and no points to be hits for foreground painters.
  ///
  /// Return true if the given position corresponds to a point on the drawn
  /// image that should be considered a "hit", false if it corresponds to a
  /// point that should be considered outside the painted image, and null to use
  /// the default behavior.
  bool? hitTest(Offset position) => null;

  @override
  String toString() =>
      '${describeIdentity(this)}(${_repaint?.toString() ?? ""})';
}

///
/// SelectionPainter
///
class DefaultSelectionPainter extends SelectionPainter {
  DefaultSelectionPainter({
    required this.color,
    required this.opacityAnimation,
  }) : super(repaint: opacityAnimation);

  final Color color;
  final Animation<double>? opacityAnimation;

  @override
  void paint(Canvas canvas, Size size, Selection selection) {
    final rects = selection.rects;

    // dmPrint('SelectionPainter painting ${rects?.length ?? 0} rects.');

    if (rects != null && rects.isNotEmpty) {
      // final gradient = ui.Gradient.linear(
      //   const Offset(87.2623 + 37.9092, 28.8384 + 123.4389),
      //   const Offset(42.9205 + 37.9092, 35.0952 + 123.4389),
      //   <Color>[
      //     const Color(0x001A237E),
      //     const Color(0x661A237E),
      //   ],
      // );

      final opacity = opacityAnimation == null
          ? 1.0
          : opacityAnimation!.value.clamp(0.0, 1.0);
      final paintColor = Color.lerp(null, color, opacity);
      final paint = Paint()..color = paintColor ?? color;
      // ..shader = gradient;

      // dmPrint('DefaultSelectionPainter repainting with opacity $opacity '
      //     'from animation value ${opacity.value}');

      for (final rect in rects) {
        canvas.drawRect(rect, paint);
      }

      /*
      const radius = Radius.circular(8);
      if (rects.length == 1) {
        canvas.drawRRect(RRect.fromRectAndRadius(rects.first, radius), paint);
      } else if (rects.length == 2) {
        final r1 = rects.first;
        final r2 = rects.last;

        // If the rects are near each other.
        if (r1.isNear(r2)) {
          
        }
      } else {
      for (final rect in rects) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint)
      }
      }
      */

      /*
      final topLeft = rects.first.topLeft;
      final path = Path()..moveToPt(topLeft);

      var pt = topLeft;
      var nextPt = rects.first.topRight;

      for (final rect in rects) {
        nextPt = rect.topRight;
        if (pt != nextPt) {
          path.lineTo(rect.right, rect.top);
        }
      }

      final bottomRight = rects.last.bottomRight;
      path.lineToPt(bottomRight);

      for (final rect in rects.reversed) {
        path.lineTo(rect.left, rect.bottom);
      }

      path.lineToPt(topLeft);

      canvas.drawPath(path, paint);
      */
    }
  }

  @override
  bool shouldRepaint(DefaultSelectionPainter oldDelegate) {
    final needsRepaint = color != oldDelegate.color ||
        opacityAnimation != oldDelegate.opacityAnimation;
    // dmPrint('SelectionPainter '
    //     '${needsRepaint ? 'needs repaint' : 'does not need repaint'}');
    return needsRepaint;
  }
}

/*
extension on Path {
  void moveToPt(Offset pt) => moveTo(pt.dx, pt.dy);

  void lineToPt(Offset pt) => lineTo(pt.dx, pt.dy);
}
*/
