// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

// The default test font renders every glyph as a square with sides equal to
// the font size, so with `fontSize: 10` and `height: 1.0`, every glyph is
// exactly 10 wide and every line is exactly 10 high, making the layout below
// exact.
const _style = TextStyle(fontSize: 10, height: 1.0);

// Forty distinct three-character words ('w00' through 'w39'), so that if the
// hidden word float_column appends to a justified chunk (to justify its last
// line) leaks into selectable's text or selections, it shows up as a
// duplicated word.
final _words = List.generate(
  40,
  (i) => 'w${i.toString().padLeft(2, '0')}',
).join(' ');

void main() {
  group('TextAlign.justify with float_column hidden appended words', () {
    testWidgets('getContainedText does not include the hidden word', (
      tester,
    ) async {
      final controller = await _pump(tester);

      expect(controller.getContainedText(), _words);
      expect(controller.containedTextLength, _words.length);
    });

    testWidgets('select all does not include the hidden word', (tester) async {
      final controller = await _pump(tester);

      expect(controller.selectAll(), isTrue);
      await tester.pump();

      expect(controller.getSelection()!.text, _words);
    });

    testWidgets('selectWordAtIndex is not confused by hidden spans', (
      tester,
    ) async {
      final controller = await _pump(tester);

      // Global character index 61 is the '1' in the second chunk's leading
      // word 'w15'. Note, without special handling, it would also incorrectly
      // match the first chunk's hidden appended span, which contains a hidden
      // copy of 'w15', anchoring the selection to the wrong word.
      expect(controller.selectWordAtIndex(61), isTrue);
      await tester.pump();

      expect(controller.getSelection()!.text, 'w15');
    });

    testWidgets(
      'extending the selection across the chunk boundary does not select '
      'the hidden word',
      (tester) async {
        final controller = await _pump(tester);

        // A point in the middle of 'w00' on the first line of the first
        // chunk, which starts at x 100, to the right of the float.
        const startPt = Offset(105.0, 5.0);

        // A point on the first line of the second chunk (y 30 to 40). Note,
        // its x position is inside the first chunk's x range (100 to 300),
        // so if the first chunk's hidden extra line is not excluded from its
        // rect, this point incorrectly resolves to the hidden word.
        const endPt = Offset(125.0, 35.0);

        expect(controller.selectWordsBetweenPoints(startPt, endPt), isTrue);
        await tester.pump();

        final text = controller.getSelection()!.text!;
        expect(text, isNotEmpty);
        expect(
          _words.contains(text),
          isTrue,
          reason:
              'The selected text should be a contiguous substring of the '
              'paragraph’s text, but it is "$text".',
        );
      },
    );
  });
}

/// Pumps a Selectable containing a FloatColumn with a floated box and a
/// justified paragraph that wraps around it, splitting the paragraph into a
/// 200 wide chunk with three lines of five words each (beside the float), and
/// a 300 wide chunk with the rest of the words below it.
///
/// Since the paragraph is justified, float_column appends a hidden copy of
/// the second chunk's leading word ('w15') to the first chunk, on an extra
/// clipped line, to force justification of the first chunk's last line.
Future<SelectableController> _pump(WidgetTester tester) async {
  final controller = SelectableController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: FloatColumn(
                children: [
                  const Floatable(
                    float: FCFloat.left,
                    child: SizedBox(width: 100, height: 25),
                  ),
                  WrappableText(
                    text: TextSpan(style: _style, text: _words),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Sanity check that the FloatColumn is at the Selectable's top left, so
  // that points in the Selectable's local coordinates, e.g. the points
  // passed to `selectWordsBetweenPoints`, are also in the FloatColumn's
  // local coordinates.
  expect(
    tester.getTopLeft(find.byType(FloatColumn)),
    tester.getTopLeft(find.byType(Selectable)),
  );

  return controller;
}
