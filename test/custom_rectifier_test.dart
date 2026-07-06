// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';
import 'package:selectable/src/pan_gesture_detector.dart';

void main() {
  testWidgets('a custom rectifier that returns an empty list does not cause an '
      'endless rebuild loop', (tester) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);
    controller.setCustomRectifier((rects) => []);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Selectable(
            selectionController: controller,
            child: const Text('alpha bravo'),
          ),
        ),
      ),
    );

    expect(controller.selectWordAtIndex(0), isTrue);

    // The widget tree must reach quiescence. If Selectable perpetually
    // schedules zero-duration refresh timers, this test fails at teardown
    // with 'A Timer is still pending even after the widget tree was
    // disposed' — each frame of the endless rebuild loop schedules the
    // next timer.
    await tester.pumpAndSettle();

    // The selection is retained, it just has no rects to draw.
    expect(controller.isTextSelected, isTrue);
  });

  testWidgets('the selection is computed only once per drag update', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    // The rectifier is called each time the selection is recomputed, so
    // it can be used to count selection computations.
    var rectifierCallCount = 0;
    controller.setCustomRectifier((rects) {
      rectifierCallCount++;
      return rects;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Selectable(
            selectionController: controller,
            child: const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Foo bar baz',
                style: TextStyle(fontSize: 14, height: 1.0),
              ),
            ),
          ),
        ),
      ),
    );

    // Long-press the middle of 'bar' to select it and show the handles.
    final selectableTopLeft = tester.getTopLeft(find.byType(Selectable));
    await tester.longPressAt(selectableTopLeft + const Offset(14.0 * 5.5, 7));
    await tester.pumpAndSettle();
    expect(controller.getSelection()!.text, 'bar');

    // Drag the end selection handle to the right, far enough to exceed
    // the minimum drag distance, and count the selection computations
    // triggered by the drag update.
    final handle = tester.getCenter(
      find.byType(SelectablePanGestureDetector).last,
    );
    final gesture = await tester.startGesture(handle);
    await tester.pump();

    rectifierCallCount = 0;
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();

    expect(
      rectifierCallCount,
      lessThanOrEqualTo(1),
      reason:
          'A single drag update should compute the selection at most '
          'once, not once per selection accessor.',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
