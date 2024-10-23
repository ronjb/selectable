import 'package:flutter_test/flutter_test.dart';
// import 'package:intl/intl.dart';
import 'package:selectable/src/string_utils.dart';

void main() {
  test('String.countOfWords in bible_chapter_view.dart', () {
    expect(''.countOfWords(), 0);
    expect(', and ,'.countOfWords(), 1);
    expect('dog cat rabbit'.countOfWords(), 3);
    expect("  dog  cat's  rabbit  ".countOfWords(), 3);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 2), 0);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 3), 0);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 4), 0);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 5), 1);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 6), 1);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 7), 1);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 8), 1);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 9), 1);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 10), 2);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 11), 2);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 17), 2);
    expect('  dog  cat  rabbit  '.countOfWords(toIndex: 18), 3);
    expect('  dog  cat  rabbit'.countOfWords(), 3);
    expect('"dog'.countOfWords(toIndex: 1), 0);

    // ASCII Punctuation, except the single quote char, which is a valid word
    // character.
    expect(r'!"#$%&()*+,-./:;<=>?@[\]^_`{|}~—'.countOfWords(), 0);

    // Non-word smart quote chars.
    expect('‘“”'.countOfWords(), 0);
  });

  test('String.indexAtEndOfWord in bible_chapter_view.dart', () {
    expect('dog cat rabbit'.indexAtEndOfWord(0), 0);
    expect('dog cat rabbit'.indexAtEndOfWord(100), 14);
    expect('dog cat rabbit'.indexAtEndOfWord(1), 3);
    expect('dog cat rabbit'.indexAtEndOfWord(2), 7);
    expect('  dog  cat  rabbit  '.indexAtEndOfWord(2), 10);
  });

  test('em dash test', () {
    expect('  dog—cat  rabbit'.countOfWords(), 3);
  });

  group('indexOfCharacterAfter', () {
    test('handles normal strings correctly', () {
      expect('01234567'.indexOfCharacterAfter(0), 1);
      expect('01234567'.indexOfCharacterAfter(3), 4);
      expect('01234567'.indexOfCharacterAfter(7), 8);
      expect('01234567'.indexOfCharacterAfter(8), 8);
    });

    test('throws for invalid indices', () {
      expect(() => '01234567'.indexOfCharacterAfter(-1), throwsAssertionError);
      expect(() => '01234567'.indexOfCharacterAfter(9), throwsAssertionError);
    });

    test('skips spaces in normal strings when includeWhitespace is `false`',
        () {
      expect('0123 5678'.indexOfCharacterAfter(3, includeWhitespace: false), 5);
      expect('0123 5678'.indexOfCharacterAfter(4, includeWhitespace: false), 5);
      expect(
          '0123      0123'.indexOfCharacterAfter(3, includeWhitespace: false),
          10);
      expect(
          '0123      0123'.indexOfCharacterAfter(2, includeWhitespace: false),
          3);
      expect(
          '0123      0123'.indexOfCharacterAfter(4, includeWhitespace: false),
          10);
      expect(
          '0123      0123'.indexOfCharacterAfter(9, includeWhitespace: false),
          10);
      expect(
          '0123      0123'.indexOfCharacterAfter(10, includeWhitespace: false),
          11);
      // If the subsequent characters are all whitespace, it returns the length
      // of the string.
      expect(
          '0123      '.indexOfCharacterAfter(5, includeWhitespace: false), 10);
    });

    test('handles surrogate pairs correctly', () {
      expect('0123👨👩👦0123'.indexOfCharacterAfter(3), 4);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(4), 6);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(5), 6);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(6), 8);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(7), 8);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(8), 10);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(9), 10);
      expect('0123👨👩👦0123'.indexOfCharacterAfter(10), 11);
    });

    test('handles extended grapheme clusters correctly', () {
      expect('0123👨‍👩‍👦2345'.indexOfCharacterAfter(3), 4);
      expect('0123👨‍👩‍👦2345'.indexOfCharacterAfter(4), 12);
      // Even when extent falls within an extended grapheme cluster, it still
      // identifies the whole grapheme cluster.
      expect('0123👨‍👩‍👦2345'.indexOfCharacterAfter(5), 12);
      expect('0123👨‍👩‍👦2345'.indexOfCharacterAfter(12), 13);
    });
  });

  group('indexOfCharacterBefore', () {
    test('handles normal strings correctly', () {
      expect('01234567'.indexOfCharacterBefore(8), 7);
      expect('01234567'.indexOfCharacterBefore(0), 0);
      expect('01234567'.indexOfCharacterBefore(1), 0);
      expect('01234567'.indexOfCharacterBefore(5), 4);
      expect('01234567'.indexOfCharacterBefore(8), 7);
    });

    test('throws for invalid indices', () {
      expect(() => '01234567'.indexOfCharacterBefore(-1), throwsAssertionError);
      expect(() => '01234567'.indexOfCharacterBefore(9), throwsAssertionError);
    });

    test('skips spaces in normal strings when includeWhitespace is `false`',
        () {
      expect(
          '0123 0123'.indexOfCharacterBefore(5, includeWhitespace: false), 3);
      expect(
          '0123      0123'.indexOfCharacterBefore(10, includeWhitespace: false),
          3);
      expect(
          '0123      0123'.indexOfCharacterBefore(11, includeWhitespace: false),
          10);
      expect(
          '0123      0123'.indexOfCharacterBefore(9, includeWhitespace: false),
          3);
      expect(
          '0123      0123'.indexOfCharacterBefore(4, includeWhitespace: false),
          3);
      expect(
          '0123      0123'.indexOfCharacterBefore(3, includeWhitespace: false),
          2);
      // If the previous characters are all whitespace, it returns zero.
      expect(
          '          0123'.indexOfCharacterBefore(3, includeWhitespace: false),
          0);
    });

    test('handles surrogate pairs correctly', () {
      expect('0123👨👩👦0123'.indexOfCharacterBefore(11), 10);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(10), 8);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(9), 8);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(8), 6);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(7), 6);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(6), 4);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(5), 4);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(4), 3);
      expect('0123👨👩👦0123'.indexOfCharacterBefore(3), 2);
    });

    test('handles extended grapheme clusters correctly', () {
      expect('0123👨‍👩‍👦2345'.indexOfCharacterBefore(13), 12);
      // Even when extent falls within an extended grapheme cluster, it still
      // identifies the whole grapheme cluster.
      expect('0123👨‍👩‍👦2345'.indexOfCharacterBefore(12), 4);
      expect('0123👨‍👩‍👦2345'.indexOfCharacterBefore(11), 4);
      expect('0123👨‍👩‍👦2345'.indexOfCharacterBefore(5), 4);
      expect('0123👨‍👩‍👦2345'.indexOfCharacterBefore(4), 3);
    });

    /* test('isRtlText', () {
      expect(Bidi.isRtlLanguage('ar'), true);
      expect(Bidi.isRtlLanguage('he'), true);
      expect(Bidi.isRtlLanguage('fa'), true);
      expect(Bidi.isRtlLanguage('ur'), true);
      expect(Bidi.isRtlLanguage('ps'), true);
      expect(Bidi.isRtlLanguage('yi'), true);
      expect(Bidi.isRtlLanguage('en'), false);
      // cspell: disable
      expect(Bidi.detectRtlDirectionality('مرحبا بالعالم'), true);
      expect(Bidi.estimateDirectionOfText('مرحبا بالعالم'), TextDirection.RTL);
      // cspell: enable
      expect(Bidi.detectRtlDirectionality('Hello world'), false);
      expect(Bidi.estimateDirectionOfText('Hello world'), TextDirection.LTR);
    }); */
  });
}
