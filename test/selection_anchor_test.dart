// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/src/selection_anchor.dart';

void main() {
  group('SelectionAnchor', () {
    group('centerDistanceSquaredFromPoint', () {
      SelectionAnchor makeAnchor(List<Rect> rects) {
        return SelectionAnchor(
          0,
          0,
          const TextSelection(baseOffset: 0, extentOffset: 1),
          rects,
          TextDirection.ltr,
        );
      }

      test('returns squared distance between rect center and point', () {
        // Rect centered at (50, 50).
        final anchor = makeAnchor([const Rect.fromLTWH(0, 0, 100, 100)]);

        // Point at (50, 50) — same as center, distance should be 0.
        expect(anchor.centerDistanceSquaredFromPoint(const Offset(50, 50)), 0);

        // Point at (53, 54) — distance squared = 9 + 16 = 25.
        expect(
            anchor.centerDistanceSquaredFromPoint(const Offset(53, 54)), 25.0);
      });

      test('returns correct distance for points in different quadrants', () {
        // Rect centered at (100, 0).
        final anchor = makeAnchor([const Rect.fromLTWH(90, -10, 20, 20)]);

        // Point at (0, 100) — distance squared = 10000 + 10000 = 20000.
        expect(anchor.centerDistanceSquaredFromPoint(const Offset(0, 100)),
            20000.0);
      });

      test('picks closest rect when multiple rects exist', () {
        // Rect A centered at (10, 10), Rect B centered at (100, 100).
        final anchor = makeAnchor([
          const Rect.fromLTWH(0, 0, 20, 20),
          const Rect.fromLTWH(90, 90, 20, 20),
        ]);

        // Point at (12, 12) — closest to rect A center (10,10).
        // Distance squared to A = 4 + 4 = 8.
        // Distance squared to B = 7744 + 7744 = 15488.
        final dist =
            anchor.centerDistanceSquaredFromPoint(const Offset(12, 12));
        expect(dist, 8.0);
      });

      test('returns infinity for empty rects list', () {
        final anchor = makeAnchor([]);
        expect(anchor.centerDistanceSquaredFromPoint(Offset.zero),
            double.infinity);
      });
    });

    group('Issue #6: compareTo and operators with null', () {
      test('compareTo returns positive when other is null', () {
        const anchor = SelectionAnchor(
          0,
          0,
          TextSelection(baseOffset: 0, extentOffset: 1),
          [],
          TextDirection.ltr,
        );

        // Non-null is always "greater than" null.
        expect(anchor.compareTo(null), greaterThan(0));
      });

      test('operators handle null correctly', () {
        const anchor = SelectionAnchor(
          0,
          0,
          TextSelection(baseOffset: 0, extentOffset: 1),
          [],
          TextDirection.ltr,
        );

        expect(anchor > null, isTrue);
        expect(anchor >= null, isTrue);
        expect(anchor < null, isFalse);
        expect(anchor <= null, isFalse);
      });
    });

    group('taggedTextWithParagraphs', () {
      test('returns null without crashing when paragraphIndex is out of range',
          () {
        // Anchor with paragraphIndex = 5, but we only have an empty list.
        const anchor = SelectionAnchor(
          5,
          0,
          TextSelection(baseOffset: 0, extentOffset: 1),
          [],
          TextDirection.ltr,
        );

        // Should return null, not throw a RangeError.
        expect(anchor.taggedTextWithParagraphs([]), isNull);
      });
    });
  });
}
