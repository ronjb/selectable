// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:characters/characters.dart';

extension SelectableExtOnString on String {
  /// Returns the count of words in the string. If [toIndex] if provided,
  /// returns the count of words up to, but not including, that index.
  ///
  /// Note, if [toIndex] is provided, and [toIndex] is in the middle of a word,
  /// that word is not counted. For example, if the string is 'cat dog', and
  /// [toIndex] is 0, 1, or 2, the function returns 0. If [toIndex] is 3, 4, 5,
  /// or 6, the function returns 1. If [toIndex] is 7 or null, the function
  /// returns 2.
  ///
  /// See: http://www.unicode.org/reports/tr29/#Word_Boundaries
  int countOfWords({int? toIndex}) {
    var count = 0;
    var isInWord = false;
    var i = 0;
    final units = codeUnits;
    for (final codeUnit in units) {
      final isNonWordChar = _isNonWordChar(codeUnit);
      if (isInWord) {
        if (isNonWordChar) {
          isInWord = false;
          count++;
        }
      } else if (!isNonWordChar) {
        isInWord = true;
      }
      if (toIndex != null && i >= toIndex) break;
      i++;
    }
    if (isInWord && i >= units.length) count++;
    return count;
  }

  /// Returns the index where [word] starts (or ends, if [start] is `false`).
  /// Note, the first word is word 1, and so on.
  int indexAtWord(int? word, {bool start = true}) {
    if (word == null || word <= 0) return 0;
    var wordCount = 0;
    var isInWord = false;
    var i = 0;
    final units = codeUnits;
    for (final codeUnit in units) {
      final isNonWordChar = _isNonWordChar(codeUnit);
      if (isInWord) {
        if (isNonWordChar) {
          isInWord = false;
          if (word == wordCount && !start) return i;
        }
      } else if (!isNonWordChar) {
        wordCount++;
        if (word == wordCount && start) return i;
        isInWord = true;
      }
      i++;
    }
    return i;
  }

  /// Returns the index immediately after [word]. Note, the first word is
  /// word 1, and so on.
  int indexAtEndOfWord(int word) {
    return indexAtWord(word, start: false);
  }

  /// Returns the index into this string of the next character boundary after
  /// the provided [index].
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and this string's length, inclusive. If the
  /// [index] is equal to this string's length, this string's length is
  /// returned.
  ///
  /// Setting [includeWhitespace] to `false` will only return the index of
  /// non-whitespace characters.
  int indexOfCharacterAfter(int index, {bool includeWhitespace = true}) {
    assert(index >= 0 && index <= length);
    if (index == length) return length;

    final range = CharacterRange.at(this, 0, index);
    // If index is not on a character boundary, return the next character
    // boundary.
    if (range.current.length != index) {
      return range.current.length;
    }

    range.expandNext();
    if (!includeWhitespace) {
      range.expandWhile((character) {
        return _isWhitespace(character.codeUnitAt(0));
      });
    }
    return range.current.length;
  }

  /// Returns the index into this string of the previous character boundary
  /// before the provided [index].
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and this string's length, inclusive. If index
  /// is zero, zero will be returned.
  ///
  /// Setting [includeWhitespace] to `false` will only return the index of
  /// non-space characters.
  int indexOfCharacterBefore(int index, {bool includeWhitespace = true}) {
    assert(index >= 0 && index <= length);
    if (index == 0) return 0;

    final range = CharacterRange.at(this, 0, index);
    // If index is not on a character boundary, return the previous character
    // boundary.
    if (range.current.length != index) {
      range.dropLast();
      return range.current.length;
    }

    range.dropLast();
    if (!includeWhitespace) {
      while (range.currentCharacters.isNotEmpty &&
          _isWhitespace(range.charactersAfter.first.codeUnitAt(0))) {
        range.dropLast();
      }
    }
    return range.current.length;
  }

  /// Returns `true` if the character at [index] is a whitespace character.
  bool isWhitespaceAtIndex(int index) => _isWhitespace(codeUnitAt(index));

  /// Returns `true` if the character at [index] is a non-word character.
  ///
  /// Non-word characters are whitespace characters, punctuation characters
  /// (except apostrophe characters), and the single-quote-left character,
  /// and all double quote characters.
  bool isNonWordCharacterAtIndex(int index) =>
      _isNonWordChar(codeUnitAt(index));

  /// Returns `true` if the character at [index] is an apostrophe (i.e. it is
  /// the single-quote character 0x0027, or the single-quote-right character
  /// 0x2019).
  bool isApostropheAtIndex(int index) => _isApostrophe(codeUnitAt(index));
}

/// Returns `true` if the character is a whitespace character.
bool isWhitespaceRune(int rune) => _isWhitespace(rune);

//
// PRIVATE
//

extension<T> on Set<T> {
  Set<T> subtracting(Iterable<T>? items) {
    if (items == null || items.isEmpty) return this;
    return Set.of(this)..removeAll(items);
  }
}

bool _isNonWordChar(int codeUnit) => _nonWordChars.contains(codeUnit);
final _nonWordChars = _whitespace
    .union(_asciiPunctuation)
    .union({_emDash}).subtracting([_sglQuote]).union(_nonWordQuotes);

bool _isApostrophe(int codeUnit) => _apostrophes.contains(codeUnit);
const _apostrophes = <int>{_sglQuote, _sglQtRgt};

const _sglQuote = 0x0027; // ' single quote, apostrophe
const _sglQtLft = 0x2018; // ‘ left single quote
const _sglQtRgt = 0x2019; // ’ right single quote, apostrophe
// const _sglQuotes = <int>{_sglQuote, _sglQtLft, _sglQtRgt};

const _dblQuote = 0x0022; // " double quote
const _dblQtLft = 0x201C; // “ left double quote
const _dblQtRgt = 0x201D; // ” right double quote
// const _dblQuotes = <int>{_dblQuote, _dblQtLft, _dblQtRgt};

const _emDash = 0x2014; // — em dash

const _nonWordQuotes = <int>{_sglQtLft, _dblQuote, _dblQtLft, _dblQtRgt};

// ignore: unused_element
const _allQuotes = <int>{
  _sglQuote,
  _sglQtLft,
  _sglQtRgt,
  _dblQuote,
  _dblQtLft,
  _dblQtRgt
};

// ignore: unused_element
const _nonBreakingHyphen = 0x2011; // ‑ non-breaking hyphen

// ASCII Punctuation, 0021-007E: https://www.unicode.org/charts/PDF/U0000.pdf
const _asciiPunctuation = <int>{
  0x0021, // ! exclamation mark
  0x0022, // " double quotation mark
  0x0023, // # number sign, pound sign, hash mark, crosshatch, or octothorpe
  0x0024, // $ dollar sign
  0x0025, // % percent sign
  0x0026, // & ampersand
  0x0027, // ' apostrophe or single quote
  0x0028, // ( left parenthesis
  0x0029, // ) right parenthesis
  0x002A, // * asterisk
  0x002B, // + plus sign
  0x002C, // , comma
  0x002D, // - hyphen or minus sign
  0x002E, // . period, full stop, dot, or decimal point
  0x002F, // / slash, solidus, or virgule

  /* Ignore numbers.
  0x0030, // 0
  ...
  0x0039, // 9
  */

  0x003A, // : colon
  0x003B, // ; semicolon
  0x003C, // < less-than sign, left bracket
  0x003D, // = equals sign
  0x003E, // > greater-than sign, right bracket
  0x003F, // ? question mark

  0x0040, // @ at sign, commercial at

  /* Ignore uppercase letters (capital letters).
  0x0041, // A
  ...
  0x005A, // Z
  */

  0x005B, // [ left square bracket
  0x005C, // \ backslash or reverse solidus
  0x005D, // ] right square bracket
  0x005E, // ^ circumflex accent, or up arrowhead
  0x005F, // _ underscore, low line
  0x0060, // ` grave accent

  /* Ignore lowercase letters.
  0x0061, // a
  ...
  0x007A, // z
  */

  0x007B, // { left curly bracket
  0x007C, // | vertical line or bar
  0x007D, // } right curly bracket
  0x007E, // ~ tilde
};

/// Returns `true` if the [rune] is a whitespace character.
///
/// Built by referencing the _isWhitespace functions in
/// https://api.flutter.dev/flutter/quiver.strings/isWhitespace.html
/// and
/// https://github.com/flutter/flutter/blob/master/packages/
/// flutter/lib/src/rendering/editable.dart
///
/// Tested using a switch statement vs. `set.contains()`, and using the set
/// was three times as fast!
///
/// For more info on unicode chars see http://www.unicode.org/charts/ or
/// https://www.compart.com/en/unicode/U+00A0
///
bool _isWhitespace(int rune) => _whitespace.contains(rune);

const _whitespace = <int>{
  0x0009, // [␉] horizontal tab
  0x000A, // [␊] line feed
  0x000B, // [␋] vertical tab
  0x000C, // [␌] form feed
  0x000D, // [␍] carriage return

  // Not sure we need to include these chars, so commented out for now.
  // 0x001C, // [␜] file separator
  // 0x001D, // [␝] group separator
  // 0x001E, // [␞] record separator
  // 0x001F, // [␟] unit separator

  0x0020, // [ ] space
  0x0085, // next line
  0x00A0, // [ ] no-break space
  0x1680, // [ ] ogham space mark
  0x2000, // [ ] en quad
  0x2001, // [ ] em quad
  0x2002, // [ ] en space
  0x2003, // [ ] em space
  0x2004, // [ ] three-per-em space
  0x2005, // [ ] four-per-em space
  0x2006, // [ ] six-per-em space
  0x2007, // [ ] figure space
  0x2008, // [ ] punctuation space
  0x2009, // [ ] thin space
  0x200A, // [ ] hair space
  0x202F, // [ ] narrow no-break space
  0x205F, // [ ] medium mathematical space
  0x2060, // [] zero-width no-break character or "word joiner"
  0x3000, // [　] ideographic space
};
