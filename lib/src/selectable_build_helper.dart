// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'common.dart';
import 'pan_gesture_detector.dart';
import 'selection.dart';
import 'selection_controls.dart';

class SelectableBuildHelper {
  bool usingCupertinoControls = false;
  SelectionControls? controls;

  bool showPopupMenu = false;
  bool isScrolling = false;

  bool showParagraphRects = false; //kDebugMode;

  void maybeAutoscroll(
    ScrollController? scrollController,
    GlobalKey globalKey,
    Offset? selectionPt,
    double maxY,
    double topOverlayHeight,
  ) {
    if (scrollController?.hasOneClient ?? false) {
      _autoscroll(
          scrollController, globalKey, selectionPt, maxY, topOverlayHeight);
    }
  }

  /// Autoscrolls if the drag point is near the top or bottom of the viewport.
  void _autoscroll(ScrollController? scrollController, GlobalKey globalKey,
      Offset? dragPt, double maxY, double topOverlayHeight) {
    assert(scrollController?.hasOneClient ?? false);

    final renderObject = globalKey.currentContext!.findRenderObject();
    if (!(renderObject is RenderBox && renderObject.hasSize)) {
      return;
    }

    final vp = RenderAbstractViewport.maybeOf(renderObject);
    assert(vp != null);
    if (vp == null) return;

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
      final newScrollOffset = math.min(
          renderObjectBottom - viewportExtent + 100.0,
          math.max(-renderObjectTop,
              scrollOffset + (scrollDelta * scrollDistanceMultiplier)));
      unawaited(scrollController.animateTo(newScrollOffset + renderObjectTop,
          duration: const Duration(milliseconds: 250), curve: Curves.ease));
    }
  }

  /// Builds the selection handles and optionally the popup menu.
  List<Widget> buildSelectionControls(
    Selection? selection,
    BuildContext context,
    BoxConstraints constraints,
    SelectionDelegate selectionDelegate,
    GlobalKey mainKey,
    ScrollController? scrollController,
    double topOverlayHeight,
  ) {
    // If there is no selection, return an empty list.
    if (selection == null || !selection.isTextSelected) return []; //------->

    final leftLineHeight = selection.rects!.first.height;
    final rightLineHeight = selection.rects!.last.height;

    final leftOffset =
        controls!.getHandleAnchor(TextSelectionHandleType.left, leftLineHeight);
    final rightOffset = controls!
        .getHandleAnchor(TextSelectionHandleType.right, rightLineHeight);

    final leftHandlePt = selection.rects!.first.bottomLeft;
    final rightHandlePt = (usingCupertinoControls
        ? selection.rects!.last.topRight
        : selection.rects!.last.bottomRight);

    final leftPt = Offset(
        leftHandlePt.dx - leftOffset.dx, leftHandlePt.dy - leftOffset.dy);
    final rightPt = Offset(rightHandlePt.dx - rightOffset.dx, rightHandlePt.dy);

    final leftSize = controls!.getHandleSize(leftLineHeight);
    final rightSize = controls!.getHandleSize(rightLineHeight);

    final leftRect =
        Rect.fromLTWH(leftPt.dx, leftPt.dy, leftSize.width, leftSize.height)
            .inflate(20);
    final rightRect =
        Rect.fromLTWH(rightPt.dx, rightPt.dy, rightSize.width, rightSize.height)
            .inflate(20);

    final isShowingPopupMenu = (showPopupMenu && !isScrolling);
    // dmPrint('SelectionUpdater.buildSelectionControls isShowingPopupMenu ==
    // $isShowingPopupMenu');
    // dmPrint('buildSelectionControls, showPopupMenu = $showPopupMenu,
    // isScrolling = $isScrolling');

    return [
      Positioned.fromRect(
        rect: leftRect,
        child: _SelectionHandle(
          delegate: selectionDelegate,
          handleType: SelectionHandleType.left,
          mainKey: mainKey,
          child: controls!.buildHandle(
              context, TextSelectionHandleType.left, leftLineHeight),
        ),
      ),
      Positioned.fromRect(
        rect: rightRect,
        child: _SelectionHandle(
          delegate: selectionDelegate,
          handleType: SelectionHandleType.right,
          mainKey: mainKey,
          child: controls!.buildHandle(
              context, TextSelectionHandleType.right, rightLineHeight),
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
            selectionRects: selection.rects!,
            topOverlayHeight: topOverlayHeight,
            isShowing: isShowingPopupMenu,
          ),
        ),
      ),
    ];
  }
}

class _PopupMenu extends StatefulWidget {
  const _PopupMenu({
    required this.constraints,
    required this.controls,
    required this.mainKey,
    required this.scrollController,
    required this.selectionDelegate,
    required this.selectionRects,
    required this.topOverlayHeight,
    required this.isShowing,
  });

  final BoxConstraints constraints;
  final SelectionControls controls;
  final GlobalKey mainKey;
  final ScrollController? scrollController;
  final SelectionDelegate selectionDelegate;
  final List<Rect> selectionRects;
  final double topOverlayHeight;
  final bool isShowing;

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
      if (widget.scrollController?.hasOneClient ?? false) {
        final renderObject = widget.mainKey.currentContext!.findRenderObject();
        final vp = RenderAbstractViewport.maybeOf(renderObject);
        assert(vp != null);
        if (vp != null) {
          try {
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
          } catch (e) {
            dmPrint('Selectable popup menu build error: $e');
          }
        }
        // } else {
        //   if (widget.scrollController == null) {
        //     dmPrint('scrollController == null');
        //   } else {
        //     dmPrint('scrollController.clientCount: '
        //         '${widget.scrollController!.clientCount}');
        //   }
      }

      if (viewport != null) {
        // dmPrint('buildPopupMenu with viewport $viewport');
        _menu = widget.controls.buildPopupMenu(
            context, viewport, widget.selectionRects, widget.selectionDelegate);
      } else {
        _menu = const SizedBox();
      }
    }

    return _menu!;
  }
}

class _SelectionHandle extends StatelessWidget {
  const _SelectionHandle({
    required this.delegate,
    required this.handleType,
    required this.child,
    required this.mainKey,
  });

  final SelectionDelegate delegate;
  final SelectionHandleType handleType;
  final Widget child;
  final GlobalKey mainKey;

  void _onPanStart(DragStartDetails details) =>
      _onPan(details.globalPosition, details.kind);

  void _onPanUpdate(DragUpdateDetails details) =>
      _onPan(details.globalPosition, null);

  void _onPan(Offset globalPosition, PointerDeviceKind? pointerKind) {
    final mainKeyRenderObject = mainKey.currentContext!.findRenderObject();
    if (mainKeyRenderObject is RenderBox) {
      final offset = mainKeyRenderObject.globalToLocal(globalPosition);
      delegate.onDragSelectionHandleUpdate(handleType, offset,
          kind: pointerKind);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // dmPrint('onPanEnd');
    delegate.onDragSelectionHandleEnd(handleType);
  }

  void _onPanCancel() {
    // dmPrint('onPanCancel');
    delegate.onDragSelectionHandleEnd(handleType);
  }

  @override
  Widget build(BuildContext context) {
    return SelectablePanGestureDetector(
      onPanStart: _onPanStart,
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
