// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

  group('selectByMouseDrag', () {
    // Points in the middle of words: 'aaa' and 'ccc' are on line 1, 'eee' is
    // on line 2.
    const aaa = Offset(_leadingMargin + _fontSize * 1.5, _fontSize / 2);
    const ccc = Offset(_leadingMargin + _fontSize * 9.5, _fontSize / 2);
    const eee = Offset(_leadingMargin + _fontSize * 5.5, _fontSize * 1.5);

    // Returns the gesture, which is still down if [release] is false.
    Future<TestGesture> drag(
      WidgetTester tester,
      Offset from,
      Offset to, {
      PointerDeviceKind kind = PointerDeviceKind.mouse,
      Duration hold = Duration.zero,
      bool release = true,
    }) async {
      final topLeft = tester.getTopLeft(find.byType(Selectable));
      final gesture = await tester.startGesture(topLeft + from, kind: kind);
      await tester.pump(hold);
      // In steps, as a drag arrives: the first move only wins the gesture.
      for (var i = 1; i <= 4; i++) {
        await gesture.moveTo(topLeft + Offset.lerp(from, to, i / 4)!);
        await tester.pump();
      }
      if (release) {
        await gesture.up();
      }
      await tester.pumpAndSettle();
      return gesture;
    }

    testWidgets('a mouse drag selects from the pressed word to the pointer', (
      tester,
    ) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await drag(tester, aaa, eee);
      expect(controller.getSelection()!.text, 'aaa bbb ccc ddd eee');
    });

    testWidgets('a mouse drag backward selects the same words', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await drag(tester, eee, aaa);
      expect(controller.getSelection()!.text, 'aaa bbb ccc ddd eee');
    });

    testWidgets('a mouse drag that starts in the margin selects to the '
        'pointer', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      // Pressed in the margin to the left of line 1.
      await drag(tester, const Offset(50, _fontSize / 2), ccc);
      expect(controller.getSelection()!.text, 'aaa bbb ccc');
    });

    testWidgets('a new mouse drag replaces the selection', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await drag(tester, aaa, ccc);
      expect(controller.getSelection()!.text, 'aaa bbb ccc');
      // Starts below the selection's handles, which take a press on them.
      await drag(
        tester,
        eee,
        const Offset(_leadingMargin + _fontSize * 9.5, _fontSize * 1.5),
      );
      expect(controller.getSelection()!.text, 'eee fff');
    });

    testWidgets('a mouse click selects nothing', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      final topLeft = tester.getTopLeft(find.byType(Selectable));
      final gesture = await tester.startGesture(
        topLeft + aaa,
        kind: PointerDeviceKind.mouse,
      );
      // A click's few pixels of movement.
      await gesture.moveBy(const Offset(3, 2));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.isTextSelected, isFalse);
    });

    testWidgets('a touch drag selects nothing', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await drag(tester, aaa, eee, kind: PointerDeviceKind.touch);
      expect(controller.getSelection()!.isTextSelected, isFalse);
    });

    testWidgets('a mouse drag selects nothing unless asked for', (
      tester,
    ) async {
      final controller = await _pump(tester);
      await drag(tester, aaa, eee);
      expect(controller.getSelection()!.isTextSelected, isFalse);
    });

    testWidgets('the popup menu is hidden during a mouse drag', (tester) async {
      await _pump(tester, selectByMouseDrag: true);
      final gesture = await drag(tester, aaa, eee, release: false);
      expect(_isShowingPopupMenu(tester), isFalse);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_isShowingPopupMenu(tester), isTrue);
    });

    testWidgets('a canceled mouse drag shows the popup menu', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      final gesture = await drag(tester, aaa, eee, release: false);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'aaa bbb ccc ddd eee');
      expect(_isShowingPopupMenu(tester), isTrue);
    });

    testWidgets('a mouse drag selects after the button is held still', (
      tester,
    ) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      // Held long enough to be a long press, which selects the pressed word,
      // and dragging on from there selects as a drag does.
      final gesture = await drag(
        tester,
        aaa,
        eee,
        hold: kLongPressTimeout + const Duration(milliseconds: 100),
        release: false,
      );
      expect(controller.getSelection()!.text, 'aaa bbb ccc ddd eee');
      expect(_isShowingPopupMenu(tester), isFalse);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_isShowingPopupMenu(tester), isTrue);
    });

    testWidgets('a canceled mouse drag after the button is held still shows '
        'the popup menu', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      final gesture = await drag(
        tester,
        aaa,
        eee,
        hold: kLongPressTimeout + const Duration(milliseconds: 100),
        release: false,
      );
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'aaa bbb ccc ddd eee');
      expect(_isShowingPopupMenu(tester), isTrue);
    });

    testWidgets('without selectWordOnLongPress, a mouse drag selects after the '
        'button is held still', (tester) async {
      final controller = await _pump(
        tester,
        selectByMouseDrag: true,
        selectWordOnLongPress: false,
      );
      await drag(
        tester,
        aaa,
        eee,
        hold: kLongPressTimeout + const Duration(milliseconds: 100),
      );
      expect(controller.getSelection()!.text, 'aaa bbb ccc ddd eee');
      expect(_isShowingPopupMenu(tester), isTrue);
    });

    testWidgets('a mouse long press still selects a word', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(Selectable)) + aaa,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'aaa');
    });

    testWidgets('a touch long press still selects a word', (tester) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(Selectable)) + aaa,
      );
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'aaa');
    });

    testWidgets('moving after a touch long press still selects only the word', (
      tester,
    ) async {
      final controller = await _pump(tester, selectByMouseDrag: true);
      await drag(
        tester,
        aaa,
        eee,
        kind: PointerDeviceKind.touch,
        hold: kLongPressTimeout + const Duration(milliseconds: 100),
      );
      expect(controller.getSelection()!.text, 'aaa');
    });

    testWidgets('with it off, a mouse long press still selects a word', (
      tester,
    ) async {
      final controller = await _pump(tester);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(Selectable)) + aaa,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'aaa');
    });

    testWidgets('with selectWordOnDoubleTap, a mouse double-click selects a '
        'word', (tester) async {
      final controller = await _pump(
        tester,
        selectByMouseDrag: true,
        selectWordOnDoubleTap: true,
      );
      final pt = tester.getTopLeft(find.byType(Selectable)) + aaa;
      await tester.tapAt(pt, kind: PointerDeviceKind.mouse);
      await tester.pump(kDoubleTapMinTime);
      await tester.tapAt(pt, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'aaa');
    });

    testWidgets('on iOS, a mouse click on the selection shows and hides the '
        'popup menu', (tester) async {
      await _pump(
        tester,
        selectByMouseDrag: true,
        platform: TargetPlatform.iOS,
      );
      await drag(tester, aaa, ccc);
      expect(_isShowingPopupMenu(tester), isTrue);

      // Clicks in the middle of the selection, away from its handles.
      final bbb = tester.getTopLeft(find.byType(Selectable)) + (aaa + ccc) / 2;
      await tester.tapAt(bbb, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_isShowingPopupMenu(tester), isFalse);

      await tester.tapAt(bbb, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_isShowingPopupMenu(tester), isTrue);
    });

    testWidgets('turning it on or off keeps the child', (tester) async {
      await _pump(tester);
      final child = tester.element(find.text(_paragraphText));

      // A new element would be a new state for everything in the child.
      await _pump(tester, selectByMouseDrag: true);
      expect(tester.element(find.text(_paragraphText)), same(child));
      await _pump(tester);
      expect(tester.element(find.text(_paragraphText)), same(child));
    });
  });
}

/// Pumps a Selectable containing a two-line paragraph that is inset from
/// the Selectable's left edge, so there are margins on both sides of the
/// paragraph.
Future<SelectableController> _pump(
  WidgetTester tester, {
  bool selectByMouseDrag = false,
  bool selectWordOnLongPress = true,
  bool selectWordOnDoubleTap = false,
  TargetPlatform? platform,
}) async {
  final controller = SelectableController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          selectByMouseDrag: selectByMouseDrag,
          selectWordOnLongPress: selectWordOnLongPress,
          selectWordOnDoubleTap: selectWordOnDoubleTap,
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

/// Whether the popup menu is showing. It is hidden by fading it out, and while
/// it is hidden, its items may not be built.
bool _isShowingPopupMenu(WidgetTester tester) {
  final menu = find.ancestor(
    of: find.text('Copy'),
    matching: find.byType(AnimatedOpacity),
  );
  return menu.evaluate().isNotEmpty &&
      tester.widget<AnimatedOpacity>(menu.first).opacity == 1.0;
}
