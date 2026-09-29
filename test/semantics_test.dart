// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:selectable/selectable.dart';

void main() {
  testWidgets(
    'each text widget in a Selectable is its own semantics node, without '
    'gesture actions',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Selectable(
              child: Column(children: [Text('alpha'), Text('bravo')]),
            ),
          ),
        ),
      );

      // Selectable's gestures need a pointer position, which a semantics
      // action doesn't have, so they must not be offered to assistive
      // technologies — or merge the child text into one node.
      expect(
        tester.getSemantics(find.text('alpha')),
        isSemantics(
          label: 'alpha',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
      );
      expect(
        tester.getSemantics(find.text('bravo')),
        isSemantics(
          label: 'bravo',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
      );

      handle.dispose();
    },
  );

  testWidgets(
    'text that IgnoreSelectable makes unselectable can still be read',
    (tester) async {
      final handle = tester.ensureSemantics();

      // The IgnoreSelectable is the Selectable's only text, so its label is
      // 'bravo' whether or not the Selectable merges its child text.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Selectable(child: IgnoreSelectable(child: Text('bravo'))),
          ),
        ),
      );

      expect(find.bySemanticsLabel('bravo'), findsOneWidget);

      handle.dispose();
    },
  );

  testWidgets(
    'IgnoreSelectable with ignoringSemantics: true hides its child from '
    'assistive technologies',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Selectable(
              child: Column(
                children: [
                  Text('alpha'),
                  IgnoreSelectable(
                    ignoringSemantics: true,
                    child: Text('bravo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 'alpha' being found shows that the semantics tree was built, so
      // 'bravo' not being found means it was hidden.
      expect(find.bySemanticsLabel('alpha'), findsOneWidget);
      expect(find.bySemanticsLabel('bravo'), findsNothing);

      handle.dispose();
    },
  );
}
