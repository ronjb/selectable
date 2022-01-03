// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'common.dart';
import 'tagged_text.dart';

///
/// Provides a way to be notified of selection changes and a way to deselect
/// selected text.
///
class SelectableController extends ChangeNotifier {
  ///
  /// Returns `true` if text is selected.
  ///
  bool get isTextSelected => _start != null && _end != null;

  ///
  /// Returns the selected text, or null if text is not selected.
  ///
  String? get text => _text;
  String? _text;

  ///
  /// Returns the start of the selection, or null if text is not selected.
  ///
  TaggedText? get selectionStart => _start;
  TaggedText? _start;

  ///
  /// Returns the end of the selection, or null if text is not selected.
  ///
  TaggedText? get selectionEnd => _end;
  TaggedText? _end;

  ///
  /// Returns the selection rect(s).
  ///
  /// It will be from one to, at most, three rects, where the first rect
  /// is the bounding box of the first line, the second rect is the bounding
  /// box of lines 2 through N - 1 (where N is the number of lines), and the
  /// third rect is the bounding box of the last line.
  ///
  /// For example:
  /// ```
  ///                 ┌─────────────────┐
  ///                 │ first line      │
  /// ┌───────────────┴─────────────────┤
  /// │ middle line(s)                  │
  /// |                                 |
  /// ├──────────────────────┬──────────┘
  /// │ last line            │
  /// └──────────────────────┘
  /// ```
  List<Rect>? get rects => _rects;
  List<Rect>? _rects;

  ///
  /// If text is selected, deselects it.
  ///
  void deselectAll() {
    updateSelection(null, null, null, null);
  }

  ///
  /// Updates the selection. This is called by Selectable when the selection
  /// changes. It should not be called by other code.
  ///
  /// Returns `true` iff one of the properties changed and `notifyListeners`
  /// was called.
  ///
  bool updateSelection(
    TaggedText? start,
    TaggedText? end,
    String? text,
    List<Rect>? rects,
  ) {
    if (text != _text ||
        !areEqualLists(rects, _rects) ||
        start != _start ||
        end != _end) {
      _start = start;
      _end = end;
      _text = text;
      _rects = rects == null ? null : List.unmodifiable(rects);
      notifyListeners();
      return true;
    }
    return false;
  }
}
