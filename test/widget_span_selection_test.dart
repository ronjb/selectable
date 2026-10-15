// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:selectable/selectable.dart';

void main() {
  testWidgets('the text in a WidgetSpan is copied where it is drawn', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('5'),
      const TextSpan(text: ' whereby the'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    expect(
      controller.getSelection()!.text,
      'Sethite line5 whereby the\nNext paragraph.',
    );
  });

  testWidgets('the text in a WidgetSpan is not a paragraph of its own', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('5'),
      const TextSpan(text: ' whereby the'),
    ]);

    // The paragraph's text, which character indexes refer to, is unchanged.
    expect(
      controller.getContainedText(),
      'Sethite line\u{fffc} whereby theNext paragraph.',
    );
  });

  testWidgets('a WidgetSpan ending a paragraph is selected with it', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'the end.'),
      _superscript('5'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, 'the end.5\nNext paragraph.');
  });

  testWidgets('a WidgetSpan ending the last paragraph is selected with it', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'the end.'),
      _superscript('5'),
    ], hasNextParagraph: false);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, 'the end.5');
  });

  testWidgets('a WidgetSpan starting the first paragraph is selected with it', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      _superscript('1'),
      const TextSpan(text: 'In the beginning'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    expect(
      controller.getSelection()!.text,
      '1In the beginning\nNext paragraph.',
    );
  });

  testWidgets('a WidgetSpan is selected by its character index', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('5'),
      const TextSpan(text: ' whereby the'),
    ]);
    expect(controller.selectWordAtIndex('Sethite line'.length), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, '5');
  });

  testWidgets('a WidgetSpan is selected by a long press anywhere on its text', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('55'),
      const TextSpan(text: ' whereby the'),
    ]);

    // Near the start of its text, i.e. nearer the word before it.
    final drawn = tester.getRect(find.text('55'));
    await tester.longPressAt(drawn.centerLeft + const Offset(2, 0));
    await tester.pumpAndSettle();

    expect(controller.getSelection()!.text, '55');
  });

  testWidgets('a WidgetSpan whose text is drawn above its line is selected by '
      'its character index', (tester) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _offsetText('5', -12),
      const TextSpan(text: ' whereby the'),
    ]);
    expect(controller.selectWordAtIndex('Sethite line'.length), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, '5');
  });

  testWidgets('a WidgetSpan whose text is drawn over the paragraph before it '
      'is selected by its character index', (tester) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _offsetText('5', -16),
      const TextSpan(text: ' whereby the'),
    ], previousParagraphGap: 0);
    final index = controller.getContainedText().indexOf('\u{fffc}');
    expect(controller.selectWordAtIndex(index), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, '5');
  });

  testWidgets('a WidgetSpan whose text is drawn between its paragraph and the '
      'one before it is selected by its character index', (tester) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _offsetText('5', -12),
      const TextSpan(text: ' whereby the'),
    ], previousParagraphGap: 12);
    final index = controller.getContainedText().indexOf('\u{fffc}');
    expect(controller.selectWordAtIndex(index), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, '5');
  });

  testWidgets('a WidgetSpan whose text is drawn below its line keeps the line '
      'break after its paragraph', (tester) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'carbon dioxide, CO'),
      _subscript('2'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    expect(
      controller.getSelection()!.text,
      'carbon dioxide, CO2\nNext paragraph.',
    );
  });

  testWidgets(
    'the text in a WidgetSpan without an InlineSelectable is a paragraph of '
    'its own',
    (tester) async {
      final controller = SelectableController();
      addTearDown(controller.dispose);

      await _pump(tester, controller, [
        const TextSpan(text: 'Sethite line'),
        const WidgetSpan(child: Text('a note')),
        const TextSpan(text: ' whereby the'),
      ]);

      expect(
        controller.getContainedText(),
        'Sethite line\u{fffc} whereby thea noteNext paragraph.',
      );

      // A word in it can be selected by itself.
      await tester.longPressAt(tester.getCenter(find.text('a note')));
      await tester.pumpAndSettle();
      expect(controller.getSelection()!.text, 'note');
    },
  );

  testWidgets('an InlineSelectable outside a WidgetSpan has no effect', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Selectable(
            selectionController: controller,
            child: const InlineSelectable(child: Text('Alone.')),
          ),
        ),
      ),
    );

    expect(controller.getContainedText(), 'Alone.');
  });

  testWidgets('a WidgetSpan without text is not copied', (tester) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'before'),
      const WidgetSpan(child: SizedBox(width: 10, height: 10)),
      const TextSpan(text: ' after'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    expect(controller.getSelection()!.text, 'before after\nNext paragraph.');
  });

  testWidgets('a selected WidgetSpan is highlighted where its text is drawn', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('5'),
      const TextSpan(text: ' whereby the'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    final origin = tester.getTopLeft(find.byType(Selectable));
    final drawn = tester.getRect(find.text('5')).shift(-origin);
    expect(controller.getSelection()!.rects, contains(drawn));
  });

  testWidgets('the selected text is updated when a WidgetSpan’s text changes', (
    tester,
  ) async {
    final controller = SelectableController();
    addTearDown(controller.dispose);

    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('5'),
      const TextSpan(text: ' whereby the'),
    ]);
    expect(controller.selectAll(), isTrue);
    await tester.pump();

    // Only the text in the WidgetSpan changes, not the paragraph's own text.
    await _pump(tester, controller, [
      const TextSpan(text: 'Sethite line'),
      _superscript('6'),
      const TextSpan(text: ' whereby the'),
    ]);

    expect(
      controller.getSelection()!.text,
      'Sethite line6 whereby the\nNext paragraph.',
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  SelectableController controller,
  List<InlineSpan> spans, {
  double? previousParagraphGap,
  bool hasNextParagraph = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Selectable(
          selectionController: controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previousParagraphGap != null) ...[
                const Text('Previous paragraph.'),
                SizedBox(height: previousParagraphGap),
              ],
              Text.rich(TextSpan(children: spans)),
              if (hasNextParagraph) const Text('Next paragraph.'),
            ],
          ),
        ),
      ),
    ),
  );
}

// A superscript drawn the only way Flutter can raise text: in a WidgetSpan,
// moved up from the baseline.
WidgetSpan _superscript(String text) => _offsetText(text, -6);

// A subscript drawn in a WidgetSpan, moved down from the baseline.
WidgetSpan _subscript(String text) => _offsetText(text, 4);

WidgetSpan _offsetText(String text, double dy) => WidgetSpan(
  alignment: PlaceholderAlignment.baseline,
  baseline: TextBaseline.alphabetic,
  child: Transform.translate(
    offset: Offset(0, dy),
    child: InlineSelectable(
      child: Text(text, style: const TextStyle(fontSize: 10)),
    ),
  ),
);
