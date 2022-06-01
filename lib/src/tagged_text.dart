// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The character code Flutter uses to represent a widget span in a string.
const objectReplacementCharacterCode = 0xFFFC; // It's invisible, but here: '￼'

///
/// Tagged text.
///
class TaggedText extends Equatable {
  /// Returns a new [TaggedText].
  const TaggedText(this.tag, this.text, this.index);

  /// Associated tag, or null if none.
  final Object? tag;

  /// Full text of the TextSpan, or an empty string if it is a WidgetSpan.
  final String text;

  /// The index of the referenced character in the [text].
  final int index;

  @override
  List<Object?> get props => [index, text, tag];

  @override
  String toString() {
    return '{ "tag": $tag, "index": $index, "text": ${jsonEncode(text)} }';
  }
}
