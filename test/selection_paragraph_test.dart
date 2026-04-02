import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/src/selection_paragraph.dart';

void main() {
  group('Issue #1: anchorAtCharIndex with null rp', () {
    test('anchorAtCharIndex returns null when rp is null', () {
      const text = 'hello world';
      final paragraph = SelectionParagraph(
        rp: null,
        rect: Rect.zero,
        text: text,
        trimmedSel: createTextSelection(text)!,
        paragraphIndex: 0,
        firstCharIndex: 0,
      );

      // This should return null, not throw a null dereference.
      expect(paragraph.anchorAtCharIndex(0), isNull);
    });

    test(
      'anchorAtCharIndex returns null when rp is null and trim is false',
      () {
        const text = 'hello world';
        final paragraph = SelectionParagraph(
          rp: null,
          rect: Rect.zero,
          text: text,
          trimmedSel: createTextSelection(text)!,
          paragraphIndex: 0,
          firstCharIndex: 0,
        );

        expect(paragraph.anchorAtCharIndex(0, trim: false), isNull);
      },
    );
  });

  group('Issue #5: rectsForSelection with null rp', () {
    test('rectsForSelection returns empty list when rp is null', () {
      const text = 'hello world';
      final paragraph = SelectionParagraph(
        rp: null,
        rect: Rect.zero,
        text: text,
        trimmedSel: createTextSelection(text)!,
        paragraphIndex: 0,
        firstCharIndex: 0,
      );

      // This should return [], not throw a null dereference.
      expect(
        paragraph.rectsForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        isEmpty,
      );
    });
  });

  group('Issue #2: anchorAtCharIndex with collapsed trimmedSel', () {
    test('anchorAtCharIndex returns null when trimmedSel is collapsed', () {
      const text = 'hello';
      const span = TextSpan(text: text);
      final paragraph = SelectionParagraph(
        rp: RenderParagraph(span, textDirection: TextDirection.ltr),
        rect: Rect.zero,
        text: text,
        // Collapsed selection: end == start == 0.
        trimmedSel: const TextSelection.collapsed(offset: 0),
        paragraphIndex: 0,
        firstCharIndex: 0,
      );

      // trimmedSel.end - 1 = -1, which causes text.codeUnitAt(-1) RangeError.
      expect(paragraph.anchorAtCharIndex(0), isNull);
    });

    test('anchorAtCharIndex returns null when trimmedSel.end equals start', () {
      const text = 'hello';
      const span = TextSpan(text: text);
      final paragraph = SelectionParagraph(
        rp: RenderParagraph(span, textDirection: TextDirection.ltr),
        rect: Rect.zero,
        text: text,
        trimmedSel: const TextSelection(baseOffset: 3, extentOffset: 3),
        paragraphIndex: 0,
        firstCharIndex: 0,
      );

      expect(paragraph.anchorAtCharIndex(3), isNull);
    });
  });

  group('Issue #6: compareTo with null', () {
    test('compareTo returns positive when other is null', () {
      const text = 'hello';
      final paragraph = SelectionParagraph(
        rp: null,
        rect: Rect.zero,
        text: text,
        trimmedSel: createTextSelection(text)!,
        paragraphIndex: 0,
        firstCharIndex: 0,
      );

      expect(paragraph.compareTo(null), greaterThan(0));
    });
  });
}
