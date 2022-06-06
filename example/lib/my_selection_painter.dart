import 'package:flutter/material.dart';
import 'package:selectable/selectable.dart';

class MySelectionPainter extends SelectionPainter {
  //MySelectionPainter() : super();

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

      // final opacity = opacityAnimation == null
      //     ? 1.0
      //     : opacityAnimation!.value.clamp(0.0, 1.0);
      // final paintColor = Color.lerp(null, color, opacity);
      // final paint = Paint().color = paintColor ?? color;
      // ..shader = gradient;

      // dmPrint('MySelectionPainter repainting with opacity $opacity '
      //     'from animation value ${opacity.value}');

      final paint = Paint()..color = Colors.red.withOpacity(0.3);
      const radius = Radius.circular(8);

      final rrects =
          rects.map((rect) => RRect.fromRectAndRadius(rect.inflate(8), radius));

      for (final rect in rrects) {
        canvas.drawRRect(rect, paint);
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
  bool shouldRepaint(MySelectionPainter oldDelegate) => false;
}

/*
extension on Path {
  void moveToPt(Offset pt) => moveTo(pt.dx, pt.dy);

  void lineToPt(Offset pt) => lineTo(pt.dx, pt.dy);
}
*/
