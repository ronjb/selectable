// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

void main() {
  testWidgets(
    'the selection is cleared when the paragraph containing it is removed',
    (tester) async {
      final controller = SelectableController();
      addTearDown(controller.dispose);

      await _pumpTexts(tester, controller, ['alpha alpha', 'bravo bravo']);

      // Select the word 'bravo' in the second paragraph.
      final index = controller.getContainedText().indexOf('bravo');
      expect(index, greaterThanOrEqualTo(0));
      expect(controller.selectWordAtIndex(index), isTrue);
      await tester.pump();
      expect(controller.isTextSelected, isTrue);
      expect(controller.getSelection()!.text, 'bravo');

      // Remove the second paragraph — the one containing the selection. The
      // remaining paragraph is an unchanged prefix of the cached paragraph
      // list, so removal must still be detected as a change.
      await _pumpTexts(tester, controller, ['alpha alpha']);
      // Note, pumpAndSettle is needed (rather than pump) because clearing
      // the selection schedules a zero-duration timer to trigger a rebuild.
      await tester.pumpAndSettle();

      expect(
        controller.isTextSelected,
        isFalse,
        reason:
            'The selection referenced text that no longer exists, so it '
            'should have been cleared.',
      );
    },
  );

  testWidgets('the selection is cleared when all paragraphs are removed', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pumpTexts(tester, controller, ['alpha alpha', 'bravo bravo']);

    // Select the word 'alpha' in the first paragraph.
    expect(controller.selectWordAtIndex(0), isTrue);
    await tester.pump();
    expect(controller.isTextSelected, isTrue);
    expect(controller.getSelection()!.text, 'alpha');

    // Remove all of the text widgets.
    await _pumpTexts(tester, controller, []);
    // Note, pumpAndSettle is needed (rather than pump) because clearing
    // the selection schedules a zero-duration timer to trigger a rebuild.
    await tester.pumpAndSettle();

    expect(
      controller.isTextSelected,
      isFalse,
      reason:
          'The selection referenced text that no longer exists, so it '
          'should have been cleared.',
    );
  });

  testWidgets(
    'the contained text is updated when the content changes, even with no '
    'selection',
    (tester) async {
      final controller = SelectableController();
      addTearDown(controller.dispose);

      await _pumpTexts(tester, controller, ['alpha']);
      expect(controller.getContainedText(), 'alpha');
      expect(controller.containedTextLength, 5);

      await _pumpTexts(tester, controller, ['alpha', 'bravo']);
      await tester.pump();
      expect(controller.getContainedText(), 'alphabravo');
      expect(controller.containedTextLength, 10);
    },
  );

  testWidgets('toggling IgnoreSelectable updates the contained text', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    Future<void> pumpWithIgnoring({required bool ignoring}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Selectable(
                selectionController: controller,
                child: Column(
                  children: [
                    const Text('alpha'),
                    IgnoreSelectable(
                      ignoring: ignoring,
                      child: const Text('bravo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    await pumpWithIgnoring(ignoring: false);
    expect(controller.getContainedText(), contains('bravo'));

    // Ignoring the text should remove it from the contained text without
    // requiring an unrelated relayout.
    await pumpWithIgnoring(ignoring: true);
    await tester.pump();
    expect(controller.getContainedText(), isNot(contains('bravo')));

    // And un-ignoring it should bring it back.
    await pumpWithIgnoring(ignoring: false);
    await tester.pump();
    expect(controller.getContainedText(), contains('bravo'));
  });
}

Future<void> _pumpTexts(
  WidgetTester tester,
  SelectableController controller,
  List<String> texts,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          child: Column(children: [for (final text in texts) Text(text)]),
        ),
      ),
    ),
  );
}
