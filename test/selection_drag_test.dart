// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';
import 'package:selectable/src/pan_gesture_detector.dart';

// In tests the default font is Ahem, where every glyph is a fontSize ×
// fontSize square, so with fontSize 14 and height 1.0, a 168px-wide box
// fits exactly 12 characters, wrapping the text into two lines:
// 'aaa bbb ccc' and 'ddd eee fff'.
const _fontSize = 14.0;
const _boxWidth = _fontSize * 12;

// The left margin between the Selectable's left edge and the paragraph.
const _leadingMargin = 100.0;

const _paragraphText = 'aaa bbb ccc ddd eee fff';

void main() {
  testWidgets(
    'extending the selection into the trailing margin selects to the end '
    'of the paragraph',
    (tester) async {
      final controller = await _pump(tester);

      // A point in the middle of 'aaa' on line 1.
      const startPt = Offset(_leadingMargin + _fontSize * 1.5, _fontSize / 2);

      // A point in the margin to the right of line 1, outside the paragraph
      // rect, vertically centered on line 1.
      const marginPt = Offset(_leadingMargin + _boxWidth + 20, _fontSize / 2);

      expect(controller.selectWordsBetweenPoints(startPt, marginPt), isTrue);
      await tester.pump();

      expect(
        controller.getSelection()!.text,
        _paragraphText,
        reason:
            'Dragging into the trailing margin should extend the '
            'selection to the end of the paragraph, mirroring how dragging '
            'into the leading margin extends it to the start.',
      );
    },
  );

  testWidgets(
    'extending the selection into the leading margin selects to the start '
    'of the paragraph',
    (tester) async {
      final controller = await _pump(tester);

      final selectableTopLeft = tester.getTopLeft(find.byType(Selectable));

      // Long-press the middle of 'eee' on line 2 to select it.
      await tester.longPressAt(
        selectableTopLeft +
            const Offset(_leadingMargin + _fontSize * 5.5, _fontSize * 1.5),
      );
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'eee');

      // Drag the start selection handle into the margin to the left of
      // line 2. Note, a mouse pointer is used so the drag point isn't
      // offset upward like it is for touch.
      final handle = tester.getCenter(
        find.byType(SelectablePanGestureDetector).first,
      );
      final gesture = await tester.startGesture(
        handle,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(
        selectableTopLeft + const Offset(50, _fontSize * 1.5),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        controller.getSelection()!.text,
        'aaa bbb ccc ddd eee',
        reason:
            'Dragging into the leading margin should extend the '
            'selection to the start of the paragraph.',
      );
    },
  );
}

/// Pumps a Selectable containing a two-line paragraph that is inset from
/// the Selectable's left edge, so there are margins on both sides of the
/// paragraph.
Future<SelectableController> _pump(WidgetTester tester) async {
  final controller = SelectableController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          child: const Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: _leadingMargin),
              child: SizedBox(
                width: _boxWidth,
                child: Text(
                  _paragraphText,
                  style: TextStyle(fontSize: _fontSize, height: 1.0),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final selectableTopLeft = tester.getTopLeft(find.byType(Selectable));
  final textRect = tester.getRect(find.byType(Text));

  // Sanity check the paragraph's position and two-line layout.
  expect(textRect.topLeft, selectableTopLeft + const Offset(_leadingMargin, 0));
  expect(textRect.height, _fontSize * 2, reason: 'expected two lines');

  return controller;
}
