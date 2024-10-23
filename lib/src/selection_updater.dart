// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/painting.dart';

import 'common.dart';
import 'selection.dart';
import 'selection_anchor.dart';
import 'selection_controls.dart';
import 'selection_paragraph.dart';
import 'selections.dart';

Selection updatedSelectionWith(
  Selection newSelection,
  Paragraphs cachedParagraphs,
  SelectionDragInfo? dragInfo,
) {
  // dmPrint('Updating selection with selectionPt: $selectionPt, handleType:'
  //     '${dragInfo.handleType}');

  var selection = newSelection;
  final selectionPt = dragInfo?.selectionPt;

  final isSelectingWord = dragInfo?.isSelectingWord ?? false;
  final isDraggingHandle = dragInfo?.isDraggingHandle ?? false;
  final paragraphs = cachedParagraphs.list;

  if (!(isSelectingWord || selection.isTextSelected) || paragraphs.isEmpty) {
    return selection.cleared(); // ----------------------------------------->
  }

  if (isSelectingWord) {
    selection = selection.cleared();
  }

  var startSelPt = selection.startPt;
  var endSelPt = selection.endPt;

  var startAnchor = selection.startAnchor;
  var endAnchor = selection.endAnchor;

  if (isDraggingHandle) {
    if ((dragInfo!.handleType == SelectionHandleType.left &&
            !dragInfo.areAnchorsSwapped) ||
        (dragInfo.handleType == SelectionHandleType.right &&
            dragInfo.areAnchorsSwapped)) {
      startAnchor = null;
      startSelPt = null;
    } else {
      endAnchor = null;
      endSelPt = null;
    }
  }

  // If text is selected, make sure anchors are updated because the layout
  // or contained text may have changed.
  if (selection.isTextSelected) {
    var clearSelection = false;
    if (startAnchor != null) {
      startAnchor = paragraphs.updateAnchor(startAnchor);
      startSelPt = startAnchor?.rects.first.center;
      clearSelection = (startAnchor == null);
    }

    if (!clearSelection && endAnchor != null) {
      endAnchor = paragraphs.updateAnchor(endAnchor);
      endSelPt = endAnchor?.textDirection == TextDirection.rtl
          ? endAnchor?.rects.last.centerLeft
          : endAnchor?.rects.last.centerRight;
      clearSelection = (endAnchor == null);
    }

    if (clearSelection) {
      return selection.cleared(); // --------------------------------------->
    }
  }

  // Local func to cache the index of the paragraph that contains the
  // selection point, if any.
  int? indexOfParagraphContainingSelectionPt;
  int? paragraphContainingSelectionPt() {
    indexOfParagraphContainingSelectionPt ??=
        paragraphs.indexWhere((p) => p.rect.contains(selectionPt!));
    return indexOfParagraphContainingSelectionPt;
  }

  // Local func that returns `true` if the selection point is in, to the left
  // of, or to the right of [paragraph].
  bool selectionPtIsInOrNextTo(SelectionParagraph paragraph) {
    return (paragraph.rect.contains(selectionPt!) ||
        (selectionPt.dy.isInRange(paragraph.rect.top, paragraph.rect.bottom) &&
            paragraphContainingSelectionPt() == -1));
  }

  // Iterate through the render paragraphs, collecting the selected `rects`
  // and a string buffer with the selected string to support `Copy`.
  //
  // Note, this algorithm assumes the render paragraphs are in the order the
  // text should be read, which generally is the case, but in some widgets,
  // such as the Stack widget, care needs to be taken to ensure the child
  // text widgets are ordered correctly.

  final rects = <Rect>[];
  final buff = StringBuffer();
  for (var i = 0; i < paragraphs.length; i++) {
    final paragraph = paragraphs[i];

    //
    // If selecting a word (e.g. via long press).
    //
    if (isSelectingWord) {
      final anchor = paragraph.anchorAtPt(selectionPt!);
      if (anchor?.containsPoint(selectionPt) ?? false) {
        dragInfo!.areAnchorsSwapped = false;
        startAnchor = endAnchor = anchor;
        startSelPt = endSelPt = selectionPt;
        rects.addAll(anchor!.rects);
        buff.write(
            paragraph.text.substring(anchor.textSel.start, anchor.textSel.end));
        break; // ------------------------------------------------>
      }
    } else {
      //
      // If dragging the start or end selection handle.
      //
      if (startAnchor == null || endAnchor == null) {
        SelectionAnchor? anchor;

        // If the selection point is above or before the starting edge of the
        // paragraph, set `anchor` to the first word in the paragraph.
        if (selectionPt!.isAbove(paragraph) ||
            (selectionPt.isBeforeStartingEdgeOf(paragraph) &&
                selectionPt.dyIsInRangeOf(paragraph))) {
          anchor = paragraph.anchorAtCharIndex(0, trim: false);
          assert(anchor != null);
        }

        // If the selection point is in this paragraph...
        if (anchor == null && selectionPtIsInOrNextTo(paragraph)) {
          anchor = paragraph.anchorAtPt(selectionPt, trim: false);
        }

        // If the selection point is below the top of and past the starting
        // edge of, or below the paragraph, but above the next paragraph
        // (if any), set `anchor` to the last word in the paragraph.
        if (anchor == null &&
            selectionPt.dy >= paragraph.rect.top &&
            selectionPt.isPastStartingEdgeOf(paragraph) &&
            (paragraphContainingSelectionPt() == i ||
                (paragraphContainingSelectionPt() == -1 &&
                    (i == paragraphs.length - 1 ||
                        selectionPt.dy < paragraphs[i + 1].rect.top)))) {
          anchor = paragraph.anchorAtCharIndex(paragraph.trimmedSel.end - 1,
              trim: false);
          assert(anchor != null);
        }

        if (anchor != null) {
          final otherAnchor = startAnchor ?? endAnchor;
          final otherSelPt = startSelPt ?? endSelPt;
          if (anchor < otherAnchor) {
            if (identical(otherAnchor, startAnchor)) {
              dragInfo!.areAnchorsSwapped = !dragInfo.areAnchorsSwapped;
            }
            startAnchor = anchor;
            endAnchor = otherAnchor;
            startSelPt = selectionPt;
            endSelPt = otherSelPt;
          } else if (anchor > otherAnchor) {
            if (identical(otherAnchor, endAnchor)) {
              dragInfo!.areAnchorsSwapped = !dragInfo.areAnchorsSwapped;
            }
            startAnchor = otherAnchor;
            endAnchor = anchor;
            startSelPt = otherSelPt;
            endSelPt = selectionPt;
          } else {
            dragInfo!.areAnchorsSwapped = false;
            startAnchor = endAnchor = anchor;
            startSelPt = endSelPt = selectionPt;
          }
        }
      }

      // If this or a previous paragraph contains the start anchor...
      if (startAnchor != null && startAnchor.paragraphIndex <= i) {
        // Get the start index of the selected text in this paragraph.
        final isStartAnchorParagraph = (startAnchor.paragraphIndex == i);
        final start = (isStartAnchorParagraph
            ? startAnchor.textSel.start
            : paragraph.trimmedSel.start);

        // Get the end index of the selected text in this paragraph.
        final isEndAnchorParagraph = ((endAnchor?.paragraphIndex ?? -1) == i);
        final end = (isEndAnchorParagraph
            ? endAnchor!.textSel.end
            : paragraph.trimmedSel.end);

        // Collect the selection rects and text, if not empty.
        final ts = createTextSelection(paragraph.text,
            baseOffset: start, extentOffset: end, trim: false);
        if (ts != null) {
          final selectionRects = paragraph.rectsForSelection(ts);
          rects.addAll(selectionRects);

          // Append the text to buff, adding zero or more carriage returns
          // depending on the position of this paragraph to the next one.
          final j = i + 1;
          final paragraphText = paragraph.text.substring(ts.start, ts.end);
          final paragraphBottom = selectionRects.last.bottom;
          final nextParagraphTop =
              paragraphs[j < paragraphs.length ? j : i].rect.top;
          if (isEndAnchorParagraph ||
              nextParagraphTop < paragraphBottom ||
              paragraph.text.endsWith(' ')) {
            // No carriage return: next paragraph is not below this one, or
            // this paragraph ends with a space.
            buff.write(paragraphText);
            if (!isEndAnchorParagraph && !paragraphText.endsWith(' ')) {
              buff.write(' ');
            }
          } else if (nextParagraphTop <
              paragraphBottom + selectionRects.first.height) {
            // One carriage return: next paragraph is on the next line.
            buff.writeln(paragraphText);
          } else {
            // Two carriage returns: next paragraph is more than a line below.
            buff
              ..writeln(paragraphText)
              ..writeln();
          }
        }

        // If this paragraph contains the end anchor, we're done!
        if (isEndAnchorParagraph) break; // -------------------->
      }
    }
  }

  // If no rects or missing an anchor, clear the selection.
  if (rects.isEmpty || startAnchor == null || endAnchor == null) {
    // dmPrint('_updateSelectionWith rects.isEmpty! :(');
    return selection.cleared(); // ----------------------------------------->
  } else {
    return Selection(
        version: cachedParagraphs.version,
        text: buff.toString(),
        start: startAnchor.taggedTextWithParagraphs(paragraphs),
        end: endAnchor.taggedTextWithParagraphs(paragraphs, end: true),
        startPt: startSelPt,
        endPt: endSelPt,
        startAnchor: startAnchor,
        endAnchor: endAnchor,
        rects: selection.rectifier(rects),
        isHidden: selection.isHidden,
        animationDuration: selection.animationDuration,
        rectifier: selection.rectifier);
  }
}

extension on Offset {
  bool isAbove(SelectionParagraph paragraph) {
    return dy < paragraph.rect.top;
  }

  bool isBeforeStartingEdgeOf(SelectionParagraph paragraph) {
    if (paragraph.isRtl) {
      return dx > paragraph.rect.right;
    } else {
      return dx < paragraph.rect.left;
    }
  }

  bool isPastStartingEdgeOf(SelectionParagraph paragraph) {
    if (paragraph.isRtl) {
      return dx <= paragraph.rect.right;
    } else {
      return dx >= paragraph.rect.left;
    }
  }

  bool dyIsInRangeOf(SelectionParagraph paragraph) {
    return dy.isInRange(paragraph.rect.top, paragraph.rect.bottom);
  }
}
