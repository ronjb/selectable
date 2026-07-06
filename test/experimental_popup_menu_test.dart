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
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'the experimental popup menu is placed just above the selection '
      'when there is room ($platform)',
      (tester) async {
        // The selected line is 150px down from the Selectable's top, leaving
        // plenty of room above the selection for the popup menu.
        const selectionTopOffset = 150.0;

        final selectableTopLeft = await _pumpAndLongPress(
          tester,
          platform,
          selectionTopOffset: selectionTopOffset,
        );
        final selectionTop = selectableTopLeft.dy + selectionTopOffset;
        final selectionCenterX =
            selectableTopLeft.dx + (_fontSize * 4 + _fontSize * 7) / 2;

        final labelRect = tester.getRect(find.text('Copy'));

        expect(
          labelRect.bottom,
          lessThanOrEqualTo(selectionTop),
          reason: 'The menu should not overlap the selection.',
        );
        expect(
          labelRect.bottom,
          greaterThanOrEqualTo(selectionTop - 45),
          reason:
              'The menu should be just above the selection, not tens of '
              'pixels away from it.',
        );
        expect(
          (labelRect.center.dx - selectionCenterX).abs(),
          lessThanOrEqualTo(60),
          reason: 'The menu should be horizontally near the selection.',
        );
      },
    );

    testWidgets(
      'the experimental popup menu is placed just below the selection '
      'when there is no room above ($platform)',
      (tester) async {
        // The selected line is at the very top of the Selectable, so the
        // menu must be placed below the selection.
        final selectableTopLeft = await _pumpAndLongPress(
          tester,
          platform,
          selectionTopOffset: 0.0,
        );
        final selectionBottom = selectableTopLeft.dy + _fontSize;

        final labelRect = tester.getRect(find.text('Copy'));

        expect(
          labelRect.top,
          greaterThanOrEqualTo(selectionBottom),
          reason: 'The menu should not overlap the selection.',
        );
        expect(
          labelRect.top,
          lessThanOrEqualTo(selectionBottom + 70),
          reason:
              'The menu should be just below the selection (leaving room '
              'for the selection handles), not tens of pixels away from it.',
        );
      },
    );
  }
}

/// Pumps a Selectable using the experimental popup menu, containing a single
/// line of text [selectionTopOffset] down from its top left, long-presses the
/// word 'bar' to select it and show the menu, and returns the Selectable's
/// global top left.
Future<Offset> _pumpAndLongPress(
  WidgetTester tester,
  TargetPlatform platform, {
  required double selectionTopOffset,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 300,
            child: Selectable(
              useExperimentalPopupMenu: true,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: selectionTopOffset),
                  child: const Text(
                    'Foo bar baz',
                    style: TextStyle(fontSize: _fontSize, height: 1.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final selectableTopLeft = tester.getTopLeft(find.byType(Selectable));

  // Long-press the middle of 'bar' (character index 5) to select it.
  await tester.longPressAt(
    selectableTopLeft + Offset(_fontSize * 5.5, selectionTopOffset + 7),
  );
  await tester.pumpAndSettle();

  expect(find.text('Copy'), findsOneWidget);

  return selectableTopLeft;
}
