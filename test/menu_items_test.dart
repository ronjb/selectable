// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

void main() {
  const defineItem = SelectableMenuItem(type: SelectableMenuItemType.define);

  testWidgets(
    'the define menu item is disabled for selections of more than two words, '
    'even when the words are separated by newlines',
    (tester) async {
      final controller = await _pumpAndSelectAll(tester);

      // The selected text spans both paragraphs, joined with a newline, so
      // it contains three words.
      expect(controller.getSelection()!.text, 'alpha\nbravo charlie');

      expect(
        defineItem.isEnabled!(controller),
        isFalse,
        reason:
            'Define should be disabled for a three-word selection, '
            'regardless of whether the words are separated by spaces or '
            'newlines.',
      );
    },
  );

  testWidgets(
    'the define menu item is enabled for selections of one or two words',
    (tester) async {
      final controller = await _pumpAndSelectAll(tester);

      // Select just 'bravo charlie' (two words).
      final index = controller.getContainedText().indexOf('bravo');
      expect(controller.selectWordsBetweenIndexes(index, null), isTrue);
      await tester.pump();
      expect(controller.getSelection()!.text, 'bravo charlie');
      expect(defineItem.isEnabled!(controller), isTrue);

      // Select just 'bravo' (one word).
      expect(controller.selectWordAtIndex(index), isTrue);
      await tester.pump();
      expect(controller.getSelection()!.text, 'bravo');
      expect(defineItem.isEnabled!(controller), isTrue);
    },
  );
}

/// Pumps a Selectable with two paragraphs and selects all of the text.
Future<SelectableController> _pumpAndSelectAll(WidgetTester tester) async {
  final controller = SelectableController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          child: const Column(children: [Text('alpha'), Text('bravo charlie')]),
        ),
      ),
    ),
  );

  expect(controller.selectAll(), isTrue);
  await tester.pump();

  return controller;
}
