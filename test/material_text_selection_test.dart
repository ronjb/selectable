import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';
import 'package:selectable/src/selection_controls.dart';

// The Material popup menu is a fixed _kPopupMenuHeight (44px) tall, so the
// label's line box must stay within it — otherwise tall glyphs (e.g. Japanese)
// are clipped, especially under accessibility text scaling.
const _popupMenuHeight = 44.0;

// The menu sits within _kPopupMenuScreenPadding (8px) of each viewport edge, so
// its width must stay within the viewport minus that padding on both sides.
const _popupMenuScreenPadding = 8.0;

// Surfaces an arbitrary set of menu items so we can render the real Material
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

Future<void> _pumpMenu(
  WidgetTester tester, {
  required List<String> titles,
  double viewportWidth = 800,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Builder(
            builder: (context) =>
                exMaterialTextSelectionControls.buildPopupMenu(
                  context,
                  Rect.fromLTWH(0, 0, viewportWidth, 600),
                  [const Rect.fromLTWH(100, 200, 50, 20)],
                  _FakeSelectionDelegate(titles),
                  0,
                  false,
                ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The menu's own surface is the only Material with elevation 4.
double _menuWidth(WidgetTester tester) => tester
    .getSize(find.byWidgetPredicate((w) => w is Material && w.elevation == 4.0))
    .width;

Future<double> _pumpMenuAndMeasureLabel(
  WidgetTester tester, {
  required TextScaler textScaler,
}) async {
  await _pumpMenu(tester, titles: ['コピー'], textScaler: textScaler);
  expect(find.text('コピー'), findsOneWidget);
  return tester.getSize(find.text('コピー')).height;
}

void main() {
  testWidgets('popup menu label has a stable, pinned line height', (
    tester,
  ) async {
    final height = await _pumpMenuAndMeasureLabel(
      tester,
      textScaler: TextScaler.noScaling,
    );

    // popupMenuTextStyle pins fontSize (16) * height (1.25) = 20, independent
    // of the ambient text style.
    expect(height, 20.0);
    expect(height, lessThan(_popupMenuHeight));
  });

  testWidgets('popup menu label fits within the 44px menu when text is scaled', (
    tester,
  ) async {
    final height = await _pumpMenuAndMeasureLabel(
      tester,
      textScaler: const TextScaler.linear(2.0),
    );

    // Without the pinned line height, tall glyphs at 2x scale reach/exceed the
    // 44px menu and get clipped; the fix keeps the label (16 * 1.25 * 2 = 40)
    // strictly inside it.
    expect(height, 40.0);
    expect(height, lessThan(_popupMenuHeight));
  });

  testWidgets('a long title ellipsizes within the viewport instead of '
      'overflowing (#6, #17)', (tester) async {
    final longTitle = ('Copy ' * 200).trim();
    await _pumpMenu(tester, titles: [longTitle]);

    // No RenderFlex overflow (horizontal width or wrapped-past-44px height).
    expect(tester.takeException(), isNull);
    // The full label is still in the tree; it is only visually ellipsized.
    expect(find.text(longTitle), findsOneWidget);
    // The menu stays within the 800px viewport minus screen padding.
    expect(
      _menuWidth(tester),
      lessThanOrEqualTo(800 - _popupMenuScreenPadding * 2),
    );
  });

  testWidgets('the menu is bounded to a narrow viewport instead of '
      'overflowing (#6)', (tester) async {
    await _pumpMenu(
      tester,
      titles: ['Copy', 'Define', 'Share', 'Translate', 'Look Up', 'Search'],
      viewportWidth: 120,
    );

    expect(tester.takeException(), isNull);
    expect(
      _menuWidth(tester),
      lessThanOrEqualTo(120 - _popupMenuScreenPadding * 2),
    );
  });
}
