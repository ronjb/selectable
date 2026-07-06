// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';
import 'package:selectable/src/selection_controls.dart';

void main() {
  testWidgets('the Material popup menu uses localized default titles', (
    tester,
  ) async {
    await _pumpMenu(tester, exMaterialTextSelectionControls);

    expect(find.text('KOPIEREN'), findsOneWidget);
    expect(find.text('NACHSCHLAGEN'), findsOneWidget);
    expect(find.text('IM WEB SUCHEN'), findsOneWidget);
  });

  testWidgets('the Cupertino popup menu uses localized default titles', (
    tester,
  ) async {
    await _pumpMenu(tester, exCupertinoTextSelectionControls);

    // Note, the Cupertino buttons prefix titles with a space when they have
    // an icon; the default items have no icons, so exact titles match.
    expect(find.text('KOPIEREN'), findsOneWidget);
    expect(find.text('NACHSCHLAGEN'), findsOneWidget);
    expect(find.text('IM WEB SUCHEN'), findsOneWidget);
  });
}

/// The default menu items (copy, define, and webSearch) with `isEnabled`
/// overridden so they show without a controller and selected text.
class _DefaultItemsDelegate with SelectionDelegate {
  @override
  SelectableController? get controller => null;

  @override
  Iterable<SelectableMenuItem> get menuItems => [
    for (final type in [
      SelectableMenuItemType.copy,
      SelectableMenuItemType.define,
      SelectableMenuItemType.webSearch,
    ])
      SelectableMenuItem(type: type, isEnabled: (_) => true),
  ];
}

Future<void> _pumpMenu(WidgetTester tester, SelectionControls controls) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        _TestMaterialLocalizationsDelegate(),
        _TestCupertinoLocalizationsDelegate(),
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => controls.buildPopupMenu(
            context,
            const Rect.fromLTWH(0, 0, 800, 600),
            [const Rect.fromLTWH(100, 200, 50, 20)],
            _DefaultItemsDelegate(),
            0,
            false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestMaterialLocalizations extends DefaultMaterialLocalizations {
  const _TestMaterialLocalizations();

  @override
  String get copyButtonLabel => 'KOPIEREN';

  @override
  String get lookUpButtonLabel => 'NACHSCHLAGEN';

  @override
  String get searchWebButtonLabel => 'IM WEB SUCHEN';
}

class _TestMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TestMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _TestMaterialLocalizations());

  @override
  bool shouldReload(_TestMaterialLocalizationsDelegate old) => false;
}

class _TestCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _TestCupertinoLocalizations();

  @override
  String get copyButtonLabel => 'KOPIEREN';

  @override
  String get lookUpButtonLabel => 'NACHSCHLAGEN';

  @override
  String get searchWebButtonLabel => 'IM WEB SUCHEN';
}

class _TestCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TestCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const _TestCupertinoLocalizations());

  @override
  bool shouldReload(_TestCupertinoLocalizationsDelegate old) => false;
}
