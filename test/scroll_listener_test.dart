// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

void main() {
  testWidgets(
    'Selectable removes its isScrolling listener from the ScrollPosition it '
    'was added to, even when the ScrollController has more than one client',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      // Start with a single scrollable containing the Selectable. Selectable
      // adds its isScrolling listener to the controller's sole position in a
      // post-frame callback.
      await tester.pumpWidget(
        _TestApp(
          controller: controller,
          includeSelectable: true,
          includeSecondScrollable: false,
        ),
      );
      await tester.pump();

      final firstPosition = controller.positions.single;
      expect(
        // Sanity check that Selectable added its listener.
        // ignore: invalid_use_of_protected_member
        firstPosition.isScrollingNotifier.hasListeners,
        isTrue,
        reason:
            'Selectable should have added a listener to the position of '
            'the scroll controller it was created with.',
      );

      // Attach a second scrollable to the same controller, so the controller
      // no longer has exactly one client. This causes Selectable to remove
      // its listener (hasOneClient is now false), which must target the
      // stored ScrollPosition, not `controller.position` (which would throw
      // or be skipped with multiple clients).
      await tester.pumpWidget(
        _TestApp(
          controller: controller,
          includeSelectable: true,
          includeSecondScrollable: true,
        ),
      );
      await tester.pump();

      // Remove the Selectable entirely so it is disposed.
      await tester.pumpWidget(
        _TestApp(
          controller: controller,
          includeSelectable: false,
          includeSecondScrollable: true,
        ),
      );
      await tester.pump();

      expect(
        // `hasListeners` is the only way to observe the leak.
        // ignore: invalid_use_of_protected_member
        firstPosition.isScrollingNotifier.hasListeners,
        isFalse,
        reason:
            'The disposed Selectable leaked its isScrolling listener on '
            'the ScrollPosition it was originally added to.',
      );
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.controller,
    required this.includeSelectable,
    required this.includeSecondScrollable,
  });

  final ScrollController controller;
  final bool includeSelectable;
  final bool includeSecondScrollable;

  @override
  Widget build(BuildContext context) {
    const text = Text(
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
      'eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    );

    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: includeSelectable
                    ? Selectable(scrollController: controller, child: text)
                    : text,
              ),
            ),
            if (includeSecondScrollable)
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: const SizedBox(height: 1000, width: 100),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
