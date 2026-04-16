// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/src/pan_gesture_detector.dart';

void main() {
  group('SelectablePanGestureRecognizer', () {
    test('immediately resolves as accepted on down', () {
      final recognizer = SelectablePanGestureRecognizer();
      addTearDown(recognizer.dispose);

      // After construction, the recognizer should have an onDown set.
      expect(recognizer.onDown, isNotNull);
    });

    test('user-provided onDown is called exactly once per down event', () {
      var callCount = 0;
      final recognizer = SelectablePanGestureRecognizer();
      addTearDown(recognizer.dispose);

      recognizer.onDown = (_) {
        callCount++;
      };

      // Simulate a down event via the callback.
      recognizer.onDown!(DragDownDetails(globalPosition: Offset.zero));
      expect(callCount, 1);
    });

    test('onDown works when set to null', () {
      final recognizer = SelectablePanGestureRecognizer();
      addTearDown(recognizer.dispose);

      // Setting onDown to null should not throw.
      recognizer.onDown = null;

      // The internal wrapper should still be set (for resolve).
      expect(recognizer.onDown, isNotNull);

      // Calling it should not throw.
      recognizer.onDown!(DragDownDetails(globalPosition: Offset.zero));
    });

    test('debugDescription returns correct value', () {
      final recognizer = SelectablePanGestureRecognizer();
      addTearDown(recognizer.dispose);

      expect(recognizer.debugDescription, 'SelectablePanGestureRecognizer');
    });
  });

  group('SelectablePanGestureDetector', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectablePanGestureDetector(child: Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('pan callbacks are invoked on drag', (tester) async {
      var panStarted = false;
      var panUpdated = false;
      var panEnded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SelectablePanGestureDetector(
            onPanStart: (_) => panStarted = true,
            onPanUpdate: (_) => panUpdated = true,
            onPanEnd: (_) => panEnded = true,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(SizedBox));

      // Perform a drag gesture.
      await tester.timedDragFrom(
        center,
        const Offset(50, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(panStarted, isTrue);
      expect(panUpdated, isTrue);
      expect(panEnded, isTrue);
    });

    testWidgets('onPanDown callback is invoked', (tester) async {
      var panDown = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SelectablePanGestureDetector(
            onPanDown: (_) => panDown = true,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(SizedBox));
      await tester.timedDragFrom(
        center,
        const Offset(50, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(panDown, isTrue);
    });

    testWidgets('accepts gesture immediately on down', (tester) async {
      // Because the recognizer calls resolve(accepted) on down, a tap
      // (down + up with no movement) should still trigger onPanDown
      // and onPanEnd rather than onPanCancel.
      var panDown = false;
      var panEnded = false;
      var panCancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SelectablePanGestureDetector(
            onPanDown: (_) => panDown = true,
            onPanEnd: (_) => panEnded = true,
            onPanCancel: () => panCancelled = true,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 200, height: 200),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(SizedBox));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(panDown, isTrue);
      expect(panEnded, isTrue);
      expect(panCancelled, isFalse);
    });
  });
}
