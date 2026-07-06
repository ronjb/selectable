// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

void main() {
  testWidgets(
    'hiding the selection with a custom duration finishes animating within '
    'that duration',
    (tester) async {
      final controller = SelectableController();
      addTearDown(controller.dispose);

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
      await tester.pumpAndSettle();

      expect(
        controller.hide(duration: const Duration(milliseconds: 200)),
        isTrue,
      );
      await tester.pump();

      // Mid-animation, frames are being scheduled.
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.binding.hasScheduledFrame,
        isTrue,
        reason: 'The hide animation should be running at 100ms.',
      );

      // 300ms in, all animations should have completed — including the
      // painted highlight's fade, which must use the requested 200ms
      // duration rather than a hardcoded one.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason:
            'The highlight fade should complete within the requested '
            '200ms duration, not keep animating for a full second.',
      );
    },
  );
}
