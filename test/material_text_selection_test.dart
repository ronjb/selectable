import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';
import 'package:selectable/src/selection_controls.dart';

// The Material popup menu is a fixed _kPopupMenuHeight (44px) tall, so the
// label's line box must stay within it — otherwise tall glyphs (e.g. Japanese)
// are clipped, especially under accessibility text scaling.
const _popupMenuHeight = 44.0;

// Surfaces a single Japanese-titled menu item so we can render the real
// Material popup menu via the public buildPopupMenu API.
class _FakeSelectionDelegate with SelectionDelegate {
  @override
  SelectableController? get controller => null;

  @override
  Iterable<SelectableMenuItem> get menuItems => [
    SelectableMenuItem(
      title: 'コピー',
      isEnabled: (_) => true,
      handler: (_) => true,
    ),
  ];
}

Future<double> _pumpMenuAndMeasureLabel(
  WidgetTester tester, {
  required TextScaler textScaler,
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
                  const Rect.fromLTWH(0, 0, 800, 600),
                  [const Rect.fromLTWH(100, 200, 50, 20)],
                  _FakeSelectionDelegate(),
                  0,
                  false,
                ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
}
