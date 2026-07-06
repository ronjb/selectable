// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';
import 'package:selectable/src/selection_controls.dart';

// In tests the default font is Ahem, where every glyph is a fontSize ×
// fontSize square, so with fontSize 14 and height 1.0, the character at
// index i occupies x in [14i, 14(i + 1)).
const _fontSize = 14.0;

// These must match the values in lib/src/cupertino/text_selection.dart. The
// space the menu needs below the selection is the menu height (43) plus the
// screen padding (8) and content distance (8), i.e. 59.
const _popupMenuHeight = 43.0;
const _popupMenuContentDistance = 8.0;

void main() {
  testWidgets(
    'the Cupertino popup menu is placed below the selection when it fits, '
    'regardless of the top screen inset',
    (tester) async {
      // The viewport is 120px tall and the selected line's bottom is at 14,
      // leaving 106px below the selection — more than the 59px the menu
      // needs (8 + 43 + 8), so the menu must be placed below the selection.
      // The 59px top screen inset is irrelevant to the space below the
      // selection and must not affect this.
      const viewportHeight = 120.0;
      const topInset = 59.0;

      final selectableTopLeft = await _pumpAndLongPress(
        tester,
        viewportHeight: viewportHeight,
        topInset: topInset,
      );

      final menuTop = tester
          .getTopLeft(find.widgetWithText(CupertinoButton, 'Copy'))
          .dy;
      expect(
        menuTop - selectableTopLeft.dy,
        _fontSize + _popupMenuContentDistance,
        reason:
            'The menu should be placed just below the selection, not '
            'jump to the center of the viewport.',
      );
    },
  );

  testWidgets(
    'the Cupertino popup menu falls back to the viewport center when there '
    'is not enough space above or below the selection',
    (tester) async {
      // The viewport is 70px tall and the selected line's bottom is at 14,
      // leaving 56px below the selection — less than the 59px the menu
      // needs, so the menu must be centered in the viewport.
      const viewportHeight = 70.0;

      final selectableTopLeft = await _pumpAndLongPress(
        tester,
        viewportHeight: viewportHeight,
        topInset: 0.0,
      );

      final menuTop = tester
          .getTopLeft(find.widgetWithText(CupertinoButton, 'Copy'))
          .dy;
      expect(
        menuTop - selectableTopLeft.dy,
        viewportHeight / 2 - _popupMenuHeight / 2,
        reason: 'The menu should be centered in the viewport.',
      );
    },
  );

  testWidgets(
    'Cupertino popup menu labels are not ellipsized when the menu fits '
    'the viewport',
    (tester) async {
      // In tests the default font is Ahem, where every glyph is a 14px
      // square (at fontSize 14), so the natural label widths are 56, 84,
      // and 266 — well within the 600px viewport, but the longest exceeds
      // an equal third of it, so it must not be truncated just because the
      // other labels are shorter.
      const labels = ['Copy', 'Define', 'A Much Longer Title'];

      await _pumpMenuInWidth(tester, labels: labels, viewportWidth: 600);

      for (final label in labels) {
        expect(
          tester.getSize(find.text(label)).width,
          // The style's -0.15 letter spacing makes each glyph slightly
          // narrower than the 14px Ahem square.
          closeTo(_fontSize * label.length, label.length.toDouble()),
          reason:
              '"$label" should be laid out at its natural width, not '
              'truncated.',
        );
      }
    },
  );

  testWidgets(
    'the Cupertino popup menu is bounded to a narrow viewport instead of '
    'overflowing',
    (tester) async {
      await _pumpMenuInWidth(
        tester,
        labels: ['Copy', 'Define', 'Share', 'Translate', 'Look Up', 'Search'],
        viewportWidth: 200,
      );

      // No RenderFlex overflow.
      expect(tester.takeException(), isNull);
    },
  );
}

/// Pumps the Cupertino popup menu with the provided menu item [labels] into
/// a viewport of the provided width. Note, in the real widget tree, the menu
/// is constrained to the width of the Selectable, which the viewport matches.
Future<void> _pumpMenuInWidth(
  WidgetTester tester, {
  required List<String> labels,
  required double viewportWidth,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: viewportWidth,
            height: 600,
            child: Builder(
              builder: (context) =>
                  exCupertinoTextSelectionControls.buildPopupMenu(
                    context,
                    Rect.fromLTWH(0, 0, viewportWidth, 600),
                    [const Rect.fromLTWH(50, 200, 50, 20)],
                    _FakeSelectionDelegate(labels),
                    0,
                    false,
                  ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Surfaces an arbitrary set of menu items so we can render the real Cupertino
// popup menu via the public buildPopupMenu API.
class _FakeSelectionDelegate with SelectionDelegate {
  _FakeSelectionDelegate(this._titles);

  final List<String> _titles;

  @override
  SelectableController? get controller => null;

  @override
  Iterable<SelectableMenuItem> get menuItems => _titles
      .map(
        (title) => SelectableMenuItem(
          title: title,
          isEnabled: (_) => true,
          handler: (_) => true,
        ),
      )
      .toList();
}

/// Pumps a Selectable with Cupertino selection controls containing a single
/// line of text at its top left, long-presses the word 'bar' to select it
/// and show the popup menu, and returns the Selectable's global top left.
Future<Offset> _pumpAndLongPress(
  WidgetTester tester, {
  required double viewportHeight,
  required double topInset,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: EdgeInsets.only(top: topInset)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 520,
                height: viewportHeight,
                child: const Selectable(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
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
    ),
  );

  final selectableTopLeft = tester.getTopLeft(find.byType(Selectable));

  // Sanity check that the text starts at the Selectable's top left.
  expect(tester.getTopLeft(find.byType(Text).first), selectableTopLeft);

  // Long-press the middle of 'bar' (character index 5) to select it.
  await tester.longPressAt(
    selectableTopLeft + const Offset(_fontSize * 5.5, _fontSize / 2),
  );
  await tester.pumpAndSettle();

  // Sanity check that the menu is showing with a Copy button, and there is
  // no space above the selection, so the menu was placed below or centered.
  expect(find.widgetWithText(CupertinoButton, 'Copy'), findsOneWidget);

  return selectableTopLeft;
}
