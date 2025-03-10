// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:collection/collection.dart' as collection;
import 'package:float_column/float_column.dart';
import 'package:flutter/rendering.dart';

import 'common.dart';
import 'ignore_selectable.dart';
import 'selection.dart';
import 'selection_paragraph.dart';

/// Selections
///
/// The [Selection]s and the cached [SelectionParagraph]s contained in the
/// Selectable widget.
class Selections {
  /// Returns the [main] selection (i.e. `this[0]`).
  Selection? get main => this[0];

  /// Returns the [Selection] with the provided key, or null if none.
  Selection? operator [](int key) => _selectionWithKey(key);

  /// Updates the [Selection] with the provided key.
  void operator []=(int key, Selection selection) {
    _selectionsMap[key] = selection;
  }

  /// Returns `true` if text is selected in any selections.
  bool get isTextSelected {
    // First make sure all selections are refreshed from cachedParagraphs?
    //
    // The call to _refreshSelectionsAsNeeded is commented out for now because
    // the only way cachedParagraphs can affect the outcome is if the selection
    // is invalidated because its range of selected text no longer exists in
    // cachedParagraphs -- and that should be handled in other code.
    //
    // _refreshSelectionsAsNeeded();

    return _selectionsMap.values.firstWhereOrNull((e) => e.isTextSelected) !=
        null;
  }

  /// If text is selected in any selections, deselects it. Returns `true` if
  /// any selections were deselected.
  bool deselectAll() {
    var didDeselectAny = false;
    for (final entry in _selectionsMap.entries) {
      if (entry.value.isTextSelected) {
        _selectionsMap[entry.key] = entry.value.cleared();
        didDeselectAny = true;
      }
    }
    return didDeselectAny;
  }

  /// Info related to selecting text via double-tap or dragging selection
  /// handles -- only used with the [main] selection.
  final dragInfo = SelectionDragInfo();

  /// The cached paragraphs.
  ///
  /// Note, the same instance of [cachedParagraphs] is shared between
  /// `_SelectableState._selections` and `SelectableController._selections`,
  /// so that they are always in sync and up to date.
  Paragraphs get cachedParagraphs => _cachedParagraphs;
  var _cachedParagraphs = Paragraphs();

  /// Returns an iterable of the non-empty selections, if any.
  Iterable<Selection> get nonEmptySelections {
    // First make sure all selections are refreshed from cachedParagraphs.
    _refreshSelectionsAsNeeded();

    return _selectionsMap.values.where((e) => e.isTextSelected);
  }

  /// Updates with the [newSelections], returning `true` if any selections
  /// changed.
  bool updateWithSelections(Selections newSelections) {
    // The same instance of [cachedParagraphs] is shared between
    // `_SelectableState._selections` and `SelectableController._selections`,
    // so that they are always in sync and up to date.
    _cachedParagraphs = newSelections.cachedParagraphs;

    final changed = !areEqualMaps(newSelections._selectionsMap, _selectionsMap);
    if (changed) {
      _selectionsMap.clear();
      for (final entry in newSelections._selectionsMap.entries) {
        _selectionsMap[entry.key] = entry.value;
      }
    }

    return changed;
  }

  //
  // PRIVATE
  //

  final _selectionsMap = <int, Selection>{};

  /// Refreshes all selections that need refreshing from cachedParagraphs.
  void _refreshSelectionsAsNeeded() {
    _selectionsMap.keys.forEach(_selectionWithKey);
  }

  /// Returns the selection with [key], after first refreshing it from
  /// cachedParagraphs if needed.
  Selection? _selectionWithKey(int key, {bool useDragInfo = true}) {
    var selection = _selectionsMap[key];
    if (selection != null) {
      final isSelectingWordOrDraggingHandle =
          useDragInfo && key == 0 && dragInfo.isSelectingWordOrDraggingHandle;
      if (isSelectingWordOrDraggingHandle ||
          (selection.isTextSelected &&
              selection.version != cachedParagraphs.version)) {
        // dmPrint('Selectable: refreshing selection $key with layout '
        //     '${cachedParagraphs.version}, selecting word or dragging '
        //     'handle: $isSelectingWordOrDraggingHandle');
        var updatedSelection = selection.updatedWith(
          cachedParagraphs,
          // Only the [main] selection (i.e. key == 0) uses [dragInfo].
          useDragInfo && key == 0 ? dragInfo : null,
        );

        // If the selection was hidden and was updated from having no selected
        // text to having selected text, unhide it.
        if (selection.isHidden &&
            !selection.isTextSelected &&
            updatedSelection.isTextSelected) {
          updatedSelection = updatedSelection.copyWith(isHidden: false);
        }

        _selectionsMap[key] = selection = updatedSelection;
      }
    }
    return selection;
  }
}

///
/// Cached paragraphs
///
class Paragraphs {
  /// The cached [SelectionParagraph]s contained in the Selectable widget.
  List<SelectionParagraph> get list => _paragraphList;
  var _paragraphList = <SelectionParagraph>[];

  /// The [version] starts at 1 and gets incremented every time the paragraph
  /// list is updated. Once it reaches the max safe int value, 0x1FFFFFFFFFFFFF,
  /// it wraps back around to 1.
  int get version => _version;
  var _version = 1;

  void _incVersion() => _version = _version.incWithJsSafeWrap();

  /// Updates the paragraph list with all [SelectionParagraph]s contained in
  /// the [renderBox].
  void updateCachedParagraphsWithRenderBox(RenderBox renderBox) {
    if (!renderBox.hasSize) {
      assert(false);
      return; //------------------------------------------------------------>
    }

    // dmPrint('Selectable: updating cached paragraphs with renderBox size: '
    //     '${renderBox.size}');

    var paragraphsHaveChanged = _paragraphList.isEmpty;
    final newParagraphs = <SelectionParagraph>[];
    var charIndex = 0;

    renderBox._visitChildrenAndTextRenderers((ro) {
      final rp = ro.asRenderParagraph();
      if (rp != null) {
        final paragraphIndex = newParagraphs.length;
        final paragraph = SelectionParagraph.from(rp,
            ancestor: renderBox,
            paragraphIndex: paragraphIndex,
            firstCharIndex: charIndex);
        if (paragraph != null) {
          // If we're not expecting the paragraph to have changed,
          // check to see if it has...
          if (!paragraphsHaveChanged) {
            final cachedParagraph = paragraphIndex < _paragraphList.length
                ? _paragraphList[paragraphIndex]
                : null;
            if (cachedParagraph == null) {
              paragraphsHaveChanged = true;
              // dmPrint('Selections: paragraph $paragraphIndex was added.');
            } else if (cachedParagraph.firstCharIndex != charIndex) {
              paragraphsHaveChanged = true;
              // dmPrint('Selections: paragraph $paragraphIndex’s first '
              //     'character index changed from '
              //     '${cachedParagraph.firstCharIndex} to $charIndex');
            } else if (cachedParagraph.text != paragraph.text) {
              paragraphsHaveChanged = true;
              // dmPrint('Selections: paragraph $paragraphIndex’s text '
              //     'changed from "${cachedParagraph.text}" to '
              //     '"${paragraph.text}"');
            } else if (cachedParagraph.rect != paragraph.rect) {
              paragraphsHaveChanged = true;
              // dmPrint('Selections: paragraph $paragraphIndex’s rect '
              //     'changed from "${cachedParagraph.rect}" to '
              //     '"${paragraph.rect}"');
            }
          }

          // dmPrint('Adding paragraph with rect: $rect, range: $trimmedSel,
          // text: "$text"\n');
          newParagraphs.add(paragraph);
          charIndex += paragraph.text.length;
        }
      }

      return true; // Continue walking the render tree.
    });

    if (_paragraphList.isEmpty && newParagraphs.isEmpty) {
      paragraphsHaveChanged = false;
    }

    // Always replace _paragraphList with newParagraphs because the
    // underlying render objects may have changed.
    _paragraphList = newParagraphs;

    if (paragraphsHaveChanged) {
      _incVersion();
      // dmPrint('Selections updated with ${newParagraphs.length} '
      //     'paragraphs.');
    } else {
      // dmPrint('Selections checked for paragraph updates, found none.');
    }
  }
}

extension on RenderObject {
  ///
  /// Walks this [RenderObject] tree in a depth-first pre-order traversal,
  /// calling [visitor] for each child.
  ///
  /// If [visitor] returns true, the walk continues, otherwise it is canceled.
  ///
  bool _visitChildrenAndTextRenderers(CancelableObjectVisitor visitor) {
    var canceled = false;

    late void Function(Object object) visitChildrenRecursively;

    void recursiveRenderObjectVisitor(RenderObject object) {
      // This is called for every child of the render object, even after the
      // [visitor] function may have returned `false` for one of the children,
      // so check if canceled before handling.
      if (!canceled) {
        canceled = !visitor(object);
        if (!canceled) visitChildrenRecursively(object);
      }
    }

    bool recursiveObjectVisitor(Object object) {
      canceled = !visitor(object);
      if (!canceled) visitChildrenRecursively(object);
      return !canceled;
    }

    visitChildrenRecursively = (object) {
      // Ignore RenderIgnoreSelectable objects if `ignoring` is true.
      if (object is RenderIgnoreSelectable && object.ignoring) return;

      if (object is VisitChildrenOfAnyTypeMixin) {
        canceled = !object.visitChildrenOfAnyType(recursiveObjectVisitor);
      } else if (object is RenderObject) {
        object.visitChildren(recursiveRenderObjectVisitor);
      }
    };

    visitChildrenRecursively(this);
    return !canceled;
  }
}
