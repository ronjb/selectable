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
  double viewportHeight = 600,
  Rect selectionRect = const Rect.fromLTWH(100, 200, 50, 20),
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Builder(
            builder: (context) =>
                exMaterialTextSelectionControls.buildPopupMenu(
                  context,
                  Rect.fromLTWH(0, 0, viewportWidth, viewportHeight),
                  [selectionRect],
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
Rect _menuRect(WidgetTester tester) => tester.getRect(
  find.byWidgetPredicate((w) => w is Material && w.elevation == 4.0),
);

double _menuWidth(WidgetTester tester) => _menuRect(tester).width;

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

  testWidgets('menu labels are not ellipsized when the menu fits the '
      'viewport', (tester) async {
    // In tests the default font is Ahem, where every glyph is a 16px square
    // (at fontSize 16), so the natural label widths are 64, 96, and 304 —
    // well within the 800px viewport, but the longest exceeds an equal
    // third of it, so it must not be truncated just because the other
    // labels are shorter.
    const labels = ['Copy', 'Define', 'A Much Longer Title'];

    await _pumpMenu(tester, titles: labels);

    for (final label in labels) {
      expect(
        tester.getSize(find.text(label)).width,
        16.0 * label.length,
        reason:
            '"$label" should be laid out at its natural width, not '
            'truncated.',
      );
    }
  });

  testWidgets('the menu buttons use the ambient app theme', (tester) async {
    await _pumpMenu(tester, titles: ['Copy'], theme: ThemeData.dark());

    // The button's effective theme should be the app's dark theme, not a
    // freshly constructed default (light) theme, so that ink effects and
    // other theme-dependent styling match the app.
    final buttonContext = tester.element(find.byType(TextButton).first);
    expect(Theme.of(buttonContext).brightness, Brightness.dark);
  });

  testWidgets('the menu placed below the selection keeps the minimum screen '
      'padding from the viewport bottom', (tester) async {
    // With the selection near the top (no room for the menu above it) and
    // 78px below the selection, the menu is placed below the selection —
    // but flush placement would leave only 4px to the viewport bottom,
    // violating the documented 8px minimum screen padding.
    const viewportHeight = 142.0;
    const selectionRect = Rect.fromLTWH(100, 50, 50, 14);

    await _pumpMenu(
      tester,
      titles: ['Copy'],
      viewportHeight: viewportHeight,
      selectionRect: selectionRect,
    );

    final menuRect = _menuRect(tester);
    expect(
      menuRect.top,
      greaterThanOrEqualTo(selectionRect.bottom),
      reason: 'The menu should not overlap the selection.',
    );
    expect(
      menuRect.bottom,
      lessThanOrEqualTo(viewportHeight - _popupMenuScreenPadding),
      reason:
          'The menu should keep the minimum screen padding from the '
          'bottom of the viewport.',
    );
  });

  testWidgets('the menu placed below the selection leaves room for the end '
      'selection handle', (tester) async {
    // With plenty of room below the selection, the menu is placed below the
    // selection handle (which extends 22px below the selection), plus the
    // 8px content distance.
    const selectionRect = Rect.fromLTWH(100, 50, 50, 14);

    await _pumpMenu(
      tester,
      titles: ['Copy'],
      viewportHeight: 300,
      selectionRect: selectionRect,
    );

    const handleSize = 22.0;
    const contentDistance = 8.0;
    expect(
      _menuRect(tester).top,
      selectionRect.bottom + handleSize + contentDistance,
    );
  });
}
