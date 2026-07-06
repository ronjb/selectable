// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

// In tests the default font is Ahem, where every glyph is a fontSize ×
// fontSize square, so with fontSize 14 and height 1.0, the character at
// index i occupies x in [14i, 14(i + 1)).
const _fontSize = 14.0;

void main() {
  testWidgets('selecting the word after a multi-space run selects the word', (
    tester,
  ) async {
    final controller = await _pumpText(tester, 'foo  bar');

    // A point on the left half of the 'b' in 'bar' (character index 5).
    final pt = _centerOfLeftHalfOfCharAt(5);
    expect(controller.selectWordAtPoint(pt), isTrue);
    await tester.pump();
    expect(controller.getSelection()!.text, 'bar');
  });

  testWidgets('selecting the word after punctuation selects the word', (
    tester,
  ) async {
    final controller = await _pumpText(tester, 'foo,bar');

    // A point on the left half of the 'b' in 'bar' (character index 4).
    final pt = _centerOfLeftHalfOfCharAt(4);
    expect(controller.selectWordAtPoint(pt), isTrue);
    await tester.pump();
    expect(controller.getSelection()!.text, 'bar');
  });

  testWidgets('selecting the word after a single space selects the word', (
    tester,
  ) async {
    final controller = await _pumpText(tester, 'foo bar');

    // A point on the left half of the 'b' in 'bar' (character index 4).
    final pt = _centerOfLeftHalfOfCharAt(4);
    expect(controller.selectWordAtPoint(pt), isTrue);
    await tester.pump();
    expect(controller.getSelection()!.text, 'bar');
  });

  testWidgets(
    'selecting at the right half of the last letter of a word selects '
    'the word',
    (tester) async {
      final controller = await _pumpText(tester, 'foo bar');

      // A point on the right half of the second 'o' in 'foo' (character
      // index 2).
      final pt = _centerOfRightHalfOfCharAt(2);
      expect(controller.selectWordAtPoint(pt), isTrue);
      await tester.pump();
      expect(controller.getSelection()!.text, 'foo');
    },
  );

  testWidgets(
    'extending the selection past a closing quote at the end of a paragraph '
    'selects the quote',
    (tester) async {
      const text = 'aaa "bb"';
      final controller = await _pumpText(tester, text);

      // Select 'aaa', then extend the selection to a point past the end of
      // the text.
      final startPt = _centerOfLeftHalfOfCharAt(1);
      const marginPt = Offset(_fontSize * text.length + 20, _fontSize / 2);
      expect(controller.selectWordsBetweenPoints(startPt, marginPt), isTrue);
      await tester.pump();

      expect(
        controller.getSelection()!.text,
        'aaa "bb"',
        reason: 'Dragging past the closing quote should select it.',
      );
    },
  );

  testWidgets('extending the selection past a period at the end of a paragraph '
      'selects the period', (tester) async {
    const text = 'aaa bb.';
    final controller = await _pumpText(tester, text);

    final startPt = _centerOfLeftHalfOfCharAt(1);
    const marginPt = Offset(_fontSize * text.length + 20, _fontSize / 2);
    expect(controller.selectWordsBetweenPoints(startPt, marginPt), isTrue);
    await tester.pump();

    expect(
      controller.getSelection()!.text,
      'aaa bb.',
      reason: 'Dragging past the trailing period should select it.',
    );
  });
}

Offset _centerOfLeftHalfOfCharAt(int i) =>
    Offset(_fontSize * i + _fontSize * 0.25, _fontSize / 2);

Offset _centerOfRightHalfOfCharAt(int i) =>
    Offset(_fontSize * i + _fontSize * 0.75, _fontSize / 2);

/// Pumps a Selectable containing a single line of [text] positioned at the
/// top left of the Selectable, so that points in Selectable-local coordinates
/// line up with the text.
Future<SelectableController> _pumpText(WidgetTester tester, String text) async {
  final controller = SelectableController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              text,
              style: const TextStyle(fontSize: _fontSize, height: 1.0),
            ),
          ),
        ),
      ),
    ),
  );

  // Sanity check that the text starts at the Selectable's top left.
  expect(
    tester.getTopLeft(find.byType(Text)),
    tester.getTopLeft(find.byType(Selectable)),
  );

  return controller;
}
