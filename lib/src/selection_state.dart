// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:math';

import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'common.dart';
import 'pan_gesture_detector.dart';
import 'selection_controls.dart';
import 'selection_paragraph.dart';
import 'tagged_text.dart';

///
/// SelectionState
///
class SelectionState {
  bool usingCupertinoControls = false;
  SelectionControls? controls;

  bool get isTextSelected => _cachedRects != null;

  bool showPopupMenu = false;
  bool isScrolling = false;

  bool showParagraphRects = false; //kDebugMode;

  String? selectedText;

  TaggedText? startTaggedText;
  TaggedText? endTaggedText;

  List<Rect>? get rects => _cachedRects;
  List<Rect>? _cachedRects;

  List<SelectionParagraph>? get cachedParagraphs => _cachedParagraphs;
  List<SelectionParagraph>? _cachedParagraphs;

  Offset? get _leftHandlePt => rects?.first.bottomLeft;
  Offset? get _rightHandlePt =>
      (usingCupertinoControls ? rects?.last.topRight : rects?.last.bottomRight);

  SelectionAnchor? _leftAnchor;
  SelectionAnchor? _rightAnchor;
  bool _areAnchorsSwapped = false;

  ///
  /// Returns true if the given point is contained in the selection.
  ///
  bool containsPoint(Offset point) =>
      _cachedRects?.containsPoint(point) ?? false;

  ///
  /// Clears the selection.
  ///
  void clear() {
    selectedText = null;
    _cachedRects = null;
    _cachedParagraphs = null;
    _leftAnchor = _rightAnchor = null;
    startTaggedText = endTaggedText = null;
  }

  ///
  /// Updates the selection state with the given render object and optional
  /// selection point and handle type.
  ///
  void update(
    RenderObject? renderObject,
    Offset? selectionPt,
    SelectionHandleType? handleType,
    ScrollController? scrollController,
    double topOverlayHeight,
  ) {
    // dmPrint('SelectionState.update(selectionPt: $selectionPt, handleType:
    // $handleType)');

    final isSelectingWord = selectionPt != null && handleType == null;
    final isDraggingHandle = selectionPt != null && handleType != null;

    if (!(isSelectingWord || isTextSelected) ||
        !(renderObject is RenderBox && renderObject.hasSize)) {
      clear();
      return; //------------------------------------------------------------>
    }

    var paragraphsHaveChanged = (_cachedParagraphs == null);

    final paragraphs = <SelectionParagraph>[];

    // Local func for collecting all the descendant render paragraphs of a
    // render object.
    bool collectParagraphs(Object ro) {
      final rp = ro is RenderParagraph
          ? RenderParagraphAdapter(ro)
          : ro is RenderTextMixin
              ? ro
              : null;
      final index = paragraphs.length;
      if (rp != null) {
        final paragraph =
            SelectionParagraph.from(rp, ancestor: renderObject, index: index);
        if (paragraph != null) {
          // If the paragraph text has changed...
          if (!paragraphsHaveChanged &&
              (index >= _cachedParagraphs!.length ||
                  _cachedParagraphs![index].text != paragraph.text)) {
            paragraphsHaveChanged = true;
            if (!isSelectingWord) return false; //-------------------------->

          }

          // dmPrint('Adding paragraph with rect: $rect, range: $trimmedSel,
          // text: "$text"\n');
          paragraphs.add(paragraph);
        }
      }
      return true;
    }

    if (!renderObject.visitChildrenAndTextRenderers(collectParagraphs)) {
      paragraphs.clear();
    }

    if (paragraphs.isEmpty) {
      //dmPrint('SelectionState.update, cancelUpdate || paragraphs.isEmpty');
      clear();
      return; //------------------------------------------------------------>
    }

    if (isSelectingWord) clear();

    if (isDraggingHandle) {
      if ((handleType == SelectionHandleType.left && !_areAnchorsSwapped) ||
          (handleType == SelectionHandleType.right && _areAnchorsSwapped)) {
        _leftAnchor = null;
      } else {
        _rightAnchor = null;
      }
    }

    const dragPtVerticalOffset = kIsWeb ? 0.0 : 30.0;
    final selPt = isDraggingHandle
        ? Offset(selectionPt!.dx, selectionPt.dy - dragPtVerticalOffset)
        : selectionPt;

    // Local func to cache the index of the paragraph that contains the
    // selection point, if any.
    int? indexOfParagraphContainingSelectionPt;
    int? paragraphContainingSelectionPt() {
      indexOfParagraphContainingSelectionPt ??=
          paragraphs.indexWhere((p) => p.rect.contains(selPt!));
      return indexOfParagraphContainingSelectionPt;
    }

    // Local func that returns `true` if the selection point is in, to the left
    // of, or to the right of the given [paragraph].
    bool selectionPtIsInOrNextTo(SelectionParagraph paragraph) {
      return (paragraph.rect.contains(selPt!) ||
          (selPt.dy.isInRange(paragraph.rect.top, paragraph.rect.bottom) &&
              paragraphContainingSelectionPt() == -1));
    }

    // Iterate through the render paragraphs, collecting the selected `rects`
    // and a string buffer with the selected string to support `Copy`.
    //
    // Note, this algorithm assumes the render paragraphs are in the order the
    // text should be read, which generally is the case, but in some widgets,
    // such as the Stack widget, care needs to be taken to ensure the child
    // text widgets are ordered correctly.
    //
    final rects = <Rect>[];
    final buff = StringBuffer();
    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];

      //
      // If selecting a word (e.g. via long press).
      //
      if (isSelectingWord) {
        final anchor = paragraph.anchorAtPt(selPt!);
        if (anchor?.containsPoint(selPt) ?? false) {
          _areAnchorsSwapped = false;
          _leftAnchor = _rightAnchor = anchor;
          rects.addAll(anchor!.rects);
          buff.write(paragraph.text
              .substring(anchor.textSel.start, anchor.textSel.end));
          break; //------------------------------------->
        }
      } else {
        //
        // If dragging the left or right selection handle.
        //
        if (_leftAnchor == null || _rightAnchor == null) {
          SelectionAnchor? anchor;

          // If the selection point is above or to the left of this paragraph,
          // set `anchor` to the first word in the paragraph.
          if (selPt!.dy < paragraph.rect.top ||
              (selPt.dx < paragraph.rect.left &&
                  selPt.dy
                      .isInRange(paragraph.rect.top, paragraph.rect.bottom))) {
            anchor = paragraph.anchorAtCharIndex(0, trim: false);
            assert(anchor != null);
          }

          // If the selection point is in this paragraph...
          if (anchor == null && selectionPtIsInOrNextTo(paragraph)) {
            anchor =
                paragraph.anchorAtPt(selPt, onlyIfInRect: true, trim: false);
          }

          // If the selection point is in, to the right of, or below the
          // paragraph, but above the next paragraph (if any), set `anchor`
          // to the last word in the paragraph.
          if (anchor == null &&
              selPt.dx > paragraph.rect.left &&
              selPt.dy > paragraph.rect.top &&
              (paragraphContainingSelectionPt() == i ||
                  (paragraphContainingSelectionPt() == -1 &&
                      (i == paragraphs.length - 1 ||
                          selPt.dy < paragraphs[i + 1].rect.top)))) {
            anchor = paragraph.anchorAtCharIndex(paragraph.trimmedSel.end - 1,
                trim: false);
            assert(anchor != null);
          }

          /* // If no anchor, and this is the last paragraph, set `anchor` to
          // the last word in the paragraph.
          if (anchor == null && i == paragraphs.length - 1) {
            anchor = paragraph.anchorAtCharIndex(paragraph.trimmedSel.end - 1,
                trim: false);
            assert(anchor != null);
          } */

          if (anchor != null) {
            final otherAnchor = _leftAnchor ?? _rightAnchor;
            if (anchor < otherAnchor) {
              if (identical(otherAnchor, _leftAnchor)) {
                _areAnchorsSwapped = !_areAnchorsSwapped;
              }
              _leftAnchor = anchor;
              _rightAnchor = otherAnchor;
            } else if (anchor > otherAnchor) {
              if (identical(otherAnchor, _rightAnchor)) {
                _areAnchorsSwapped = !_areAnchorsSwapped;
              }
              _leftAnchor = otherAnchor;
              _rightAnchor = anchor;
            } else {
              _areAnchorsSwapped = false;
              _leftAnchor = _rightAnchor = anchor;
            }
          }
        }

        // If this or a previous paragraph contains the left anchor...
        if (_leftAnchor != null && _leftAnchor!.paragraph <= i) {
          // Get the start index of the selected text in this paragraph.
          final isLeftAnchorParagraph = (_leftAnchor!.paragraph == i);
          final start = (isLeftAnchorParagraph
              ? _leftAnchor!.textSel.start
              : paragraph.trimmedSel.start);

          // Get the end index of the selected text in this paragraph.
          final isRightAnchorParagraph = ((_rightAnchor?.paragraph ?? -1) == i);
          final end = (isRightAnchorParagraph
              ? _rightAnchor!.textSel.end
              : paragraph.trimmedSel.end);

          // Collect the selection rects and text, if not empty.
          final ts = createTextSelection(paragraph.text,
              baseOffset: start, extentOffset: end, trim: false);
          if (ts != null) {
            final selectionRects = paragraph.rectsForSelection(ts);
            rects.addAll(selectionRects);

            // Append the text to buff, adding zero or more carriage returns
            // depending position of this paragraph to the next one.
            final j = i + 1;
            final paragraphText = paragraph.text.substring(ts.start, ts.end);
            final paragraphBottom = selectionRects.last.bottom;
            final nextParagraphTop =
                paragraphs[j < paragraphs.length ? j : i].rect.top;
            if (isRightAnchorParagraph || nextParagraphTop < paragraphBottom) {
              // No carriage return: next paragraph is not below this one.
              buff
                ..write(paragraphText)
                ..write(' ');
            } else if (nextParagraphTop <
                paragraphBottom + selectionRects.first.height) {
              // One carriage return: next paragraph is on the next line.
              buff.writeln(paragraphText);
            } else {
              // Two carriage returns: next paragraph is greater than a line
              // below.
              buff
                ..writeln(paragraphText)
                ..writeln();
            }
          }

          // If this paragraph contains the right anchor, we're done!
          if (isRightAnchorParagraph) break; //--------->
        }
      }
    }

    // If no rects or missing an anchor, clear the selection.
    if (rects.isEmpty || _leftAnchor == null || _rightAnchor == null) {
      //dmPrint('SelectionState.update: rects.isEmpty! :(');
      clear();
    } else {
      // Otherwise, cache the selection rects.
      _cachedRects = rects.mergedToSelectionRects();

      // Update the start and end tagged text.
      startTaggedText = _leftAnchor!.taggedTextWithParagraphs(paragraphs);
      endTaggedText =
          _rightAnchor!.taggedTextWithParagraphs(paragraphs, end: true);

      // Cache the paragraphs, stripping out the RenderTextMixin objects.
      _cachedParagraphs = paragraphs
          .map((p) => SelectionParagraph(
              rp: null,
              rect: p.rect,
              index: p.index,
              text: p.text,
              trimmedSel: p.trimmedSel))
          .toList();

      selectedText = buff.toString();

      // And, if dragging a handle, autoscroll if necessary.
      if ((scrollController?.hasClients ?? false) && isDraggingHandle) {
        _autoscroll(scrollController, renderObject, selectionPt,
            _cachedParagraphs!.last.rect.bottom, topOverlayHeight);
      }
    }
  }

  ///
  /// Autoscrolls if the drag point is near the top or bottom of the viewport.
  ///
  void _autoscroll(
      ScrollController? scrollController,
      RenderObject renderObject,
      Offset? dragPt,
      double maxY,
      double topOverlayHeight) {
    assert(scrollController?.hasClients ?? false);

    final vp = RenderAbstractViewport.of(renderObject);
    assert(vp != null);
    if (vp == null) return; //---------------------------------------------->

    final renderObjScrollPos =
        renderObject.getTransformTo(vp).getTranslation().y;
    final renderObjectTop = scrollController!.offset + renderObjScrollPos;
    final renderObjectBottom = maxY;
    final scrollOffset = -renderObjScrollPos;
    final viewportExtent = scrollController.position.viewportDimension;

    final autoscrollAreaHeight = viewportExtent / 10.0;
    const scrollDistanceMultiplier = 3.0;

    final y = dragPt!.dy;
    var scrollDelta = 0.0;

    if (scrollOffset > -topOverlayHeight &&
        y < scrollOffset + autoscrollAreaHeight + topOverlayHeight) {
      scrollDelta =
          y - (scrollOffset + autoscrollAreaHeight + topOverlayHeight);
    } else if (y > scrollOffset + viewportExtent - autoscrollAreaHeight) {
      scrollDelta = y - (scrollOffset + viewportExtent - autoscrollAreaHeight);
    }

    if (scrollDelta != 0.0) {
      final newScrollOffset = min(
          renderObjectBottom - viewportExtent + 100.0,
          max(-renderObjectTop,
              scrollOffset + (scrollDelta * scrollDistanceMultiplier)));
      scrollController.animateTo(newScrollOffset + renderObjectTop,
          duration: const Duration(milliseconds: 250), curve: Curves.ease);
    }
  }

  ///
  /// Builds the selection handles and optionally the popup menu.
  ///
  List<Widget> buildSelectionControls(
    BuildContext context,
    BoxConstraints constraints,
    SelectionDelegate selectionDelegate,
    GlobalKey mainKey,
    ScrollController? scrollController,
    double topOverlayHeight,
  ) {
    // If showing the popup menu, dragging has stopped, so reset
    // `_areAnchorsSwapped`.
    if (showPopupMenu) _areAnchorsSwapped = false;

    // If there is no selection, return an empty list.
    if (!isTextSelected) return []; //-------------------------------------->
    assert(_leftHandlePt != null && _rightHandlePt != null);

    final leftLineHeight = rects!.first.height;
    final rightLineHeight = rects!.last.height;

    final _leftOffset =
        controls!.getHandleAnchor(TextSelectionHandleType.left, leftLineHeight);
    final _rightOffset = controls!
        .getHandleAnchor(TextSelectionHandleType.right, rightLineHeight);

    final leftPt = Offset(
        _leftHandlePt!.dx - _leftOffset.dx, _leftHandlePt!.dy - _leftOffset.dy);
    final rightPt =
        Offset(_rightHandlePt!.dx - _rightOffset.dx, _rightHandlePt!.dy);

    final leftSize = controls!.getHandleSize(leftLineHeight);
    final rightSize = controls!.getHandleSize(rightLineHeight);

    final leftRect =
        Rect.fromLTWH(leftPt.dx, leftPt.dy, leftSize.width, leftSize.height)
            .inflate(20);
    final rightRect =
        Rect.fromLTWH(rightPt.dx, rightPt.dy, rightSize.width, rightSize.height)
            .inflate(20);

    final isShowingPopupMenu = (showPopupMenu && !isScrolling);
    // dmPrint('SelectionState.buildSelectionControls isShowingPopupMenu ==
    // $isShowingPopupMenu');
    // dmPrint('buildSelectionControls, showPopupMenu = $showPopupMenu,
    // isScrolling = $isScrolling');

    return [
      Positioned.fromRect(
        rect: leftRect,
        child: _SelectionHandle(
          delegate: selectionDelegate,
          handleType: SelectionHandleType.left,
          child: controls!.buildHandle(
              context, TextSelectionHandleType.left, leftLineHeight),
          mainKey: mainKey,
        ),
      ),
      Positioned.fromRect(
        rect: rightRect,
        child: _SelectionHandle(
          delegate: selectionDelegate,
          handleType: SelectionHandleType.right,
          child: controls!.buildHandle(
              context, TextSelectionHandleType.right, rightLineHeight),
          mainKey: mainKey,
        ),
      ),
      AnimatedOpacity(
        opacity: isShowingPopupMenu ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          // Ignore gestures (e.g. taps) on the popup menu if it's not showing.
          ignoring: !isShowingPopupMenu,
          child: _PopupMenu(
            constraints: constraints,
            controls: controls!,
            mainKey: mainKey,
            scrollController: scrollController,
            selectionDelegate: selectionDelegate,
            selectionRects: rects!,
            topOverlayHeight: topOverlayHeight,
            isShowing: isShowingPopupMenu,
          ),
        ),
      ),
    ];
  }
}

class _PopupMenu extends StatefulWidget {
  final BoxConstraints constraints;
  final SelectionControls controls;
  final GlobalKey mainKey;
  final ScrollController? scrollController;
  final SelectionDelegate selectionDelegate;
  final List<Rect> selectionRects;
  final double topOverlayHeight;
  final bool isShowing;

  const _PopupMenu({
    Key? key,
    required this.constraints,
    required this.controls,
    required this.mainKey,
    required this.scrollController,
    required this.selectionDelegate,
    required this.selectionRects,
    required this.topOverlayHeight,
    required this.isShowing,
  }) : super(key: key);

  @override
  _PopupMenuState createState() => _PopupMenuState();
}

class _PopupMenuState extends State<_PopupMenu> {
  @override
  void didUpdateWidget(covariant _PopupMenu old) {
    super.didUpdateWidget(old);

    // Only rebuild the menu if it is showing.
    if (widget.isShowing) _menu = null;
  }

  Widget? _menu;

  @override
  Widget build(BuildContext context) {
    if (_menu == null) {
      // dmPrint('rebuilding menu...');

      // [viewport] is the rectangle that can be seen, in render object
      // coordinates, which defaults to the render object rect.
      Rect? viewport = Rect.fromLTWH(
          0, 0, widget.constraints.maxWidth, widget.constraints.maxHeight);

      // If there is a scroll controller, update the viewport to the visible
      // rect in render object coordinates.
      if (widget.scrollController?.hasClients ?? false) {
        final renderObject = widget.mainKey.currentContext!.findRenderObject();
        final vp = RenderAbstractViewport.of(renderObject);
        assert(vp != null);
        if (vp != null) {
          final renderObjScrollPos =
              renderObject!.getTransformTo(vp).getTranslation().y;
          final scrollOffset = -renderObjScrollPos + widget.topOverlayHeight;
          final viewportExtent =
              widget.scrollController!.position.viewportDimension -
                  widget.topOverlayHeight;
          viewport =
              Rect.fromLTWH(0, scrollOffset, viewport.width, viewportExtent)
                  .intersect(viewport);
          if (viewport.height < 50) viewport = null;
        }
      }

      if (viewport != null) {
        _menu = widget.controls.buildPopupMenu(
            context, viewport, widget.selectionRects, widget.selectionDelegate);
      } else {
        _menu = Container();
      }
    }

    return _menu!;
  }
}

class _SelectionHandle extends StatelessWidget {
  const _SelectionHandle({
    Key? key,
    required this.delegate,
    required this.handleType,
    required this.child,
    required this.mainKey,
  }) : super(key: key);

  final SelectionDelegate delegate;
  final SelectionHandleType handleType;
  final Widget child;
  final GlobalKey mainKey;

  void _onPanUpdate(DragUpdateDetails details) {
    final mainKeyRenderObject = mainKey.currentContext!.findRenderObject();
    if (mainKeyRenderObject is RenderBox) {
      final offset = mainKeyRenderObject.globalToLocal(details.globalPosition);
      delegate.onDragSelectionHandleUpdate(handleType, offset);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    //dmPrint('onPanEnd');
    delegate.onDragSelectionHandleEnd(handleType);
  }

  void _onPanCancel() {
    //dmPrint('onPanCancel');
    delegate.onDragSelectionHandleEnd(handleType);
  }

  @override
  Widget build(BuildContext context) {
    return SelectablePanGestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      dragStartBehavior: DragStartBehavior.down,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(20),
        //color: Colors.orange.withAlpha(50),
        child: child,
      ),
    );
  }
}
