import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/src/selection_anchor.dart';
import 'package:selectable/src/selection_paragraph.dart';
import 'package:selectable/src/tagged_text.dart';
import 'package:selectable/src/tagged_text_span.dart';

// Ok to ignore in tests.
// ignore_for_file: prefer_const_constructors
// cspell: disable

void main() {
  test('SelectionParagraph visitChildSpans', () {
    final span = TextSpan(children: [
      tts('0'),
      tts('1'),
      TextSpan(children: [tts('2'), tts('3')]),
      tts('4'),
      tts('5')
    ]);
    const text = '012345';
    final paragraph = SelectionParagraph(
      rp: RenderParagraph(span, textDirection: TextDirection.rtl),
      rect: Rect.zero,
      text: text,
      trimmedSel: createTextSelection(text)!,
      paragraphIndex: 0,
      firstCharIndex: 0,
    );
    var i = 0;
    final result = paragraph.visitChildSpans((span, index) {
      // Ok to ignore in tests.
      // ignore: avoid_as
      expect(int.parse((span as TextSpan).text!), i++);
      return true;
    });
    expect(result, true);
  });

  test('anchor.taggedTextWithParagraphs', () {
    final span = TextSpan(
        children: [tts('0'), tts('1'), tts('2'), tts('3'), tts('4'), tts('5')]);
    const text = '012345';
    final paragraph = SelectionParagraph(
      rp: RenderParagraph(span, textDirection: TextDirection.rtl),
      rect: Rect.zero,
      text: text,
      trimmedSel: createTextSelection(text)!,
      paragraphIndex: 0,
      firstCharIndex: 0,
    );
    expect(
      SelectionAnchor(
        0,
        0,
        TextSelection(baseOffset: 0, extentOffset: 1),
        const [],
        paragraph.rp!.textDirection,
      ).taggedTextWithParagraphs([paragraph]),
      TaggedText('0', '0', 0),
    );
    expect(
      SelectionAnchor(
        0,
        0,
        TextSelection(baseOffset: 0, extentOffset: 1),
        const [],
        paragraph.rp!.textDirection,
      ).taggedTextWithParagraphs([paragraph], end: true),
      TaggedText('0', '0', 1),
    );
    expect(
      SelectionAnchor(
        0,
        0,
        TextSelection(baseOffset: 2, extentOffset: 3),
        const [],
        paragraph.rp!.textDirection,
      ).taggedTextWithParagraphs([paragraph]),
      TaggedText('2', '2', 0),
    );
    expect(
      SelectionAnchor(
        0,
        0,
        TextSelection(baseOffset: 2, extentOffset: 3),
        const [],
        paragraph.rp!.textDirection,
      ).taggedTextWithParagraphs([paragraph], end: true),
      TaggedText('2', '2', 1),
    );
    expect(
      SelectionAnchor(
        0,
        0,
        TextSelection(baseOffset: 5, extentOffset: 6),
        const [],
        paragraph.rp!.textDirection,
      ).taggedTextWithParagraphs([paragraph]),
      TaggedText('5', '5', 0),
    );
    expect(
      SelectionAnchor(
        0,
        0,
        TextSelection(baseOffset: 5, extentOffset: 6),
        const [],
        paragraph.rp!.textDirection,
      ).taggedTextWithParagraphs([paragraph], end: true),
      TaggedText('5', '5', 1),
    );
  });

  test('TaggedText', () {
    final tt = TaggedText(_VerseTag(1, 2, 3), r'"test" \text', 0);
    expect(tt.toString(),
        r'{ "tag": [1, 2, 3], "index": 0, "text": "\"test\" \\text" }');
  });
}

TaggedTextSpan tts(String text, [String? tag]) =>
    TaggedTextSpan(text: text, tag: tag ?? text);

@immutable
class _VerseTag {
  const _VerseTag(this.verse, this.wordStart, this.wordEnd);

  final int verse;
  final int wordStart; // inclusive
  final int wordEnd; // exclusive

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _VerseTag &&
          runtimeType == other.runtimeType &&
          verse == other.verse &&
          wordStart == other.wordStart &&
          wordEnd == other.wordEnd;

  @override
  int get hashCode => verse.hashCode ^ wordStart.hashCode ^ wordEnd.hashCode;

  @override
  String toString() {
    return ('[$verse, $wordStart, $wordEnd]');
  }
}
