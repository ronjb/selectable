// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

library selectable;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'common.dart';
import 'selectable_build_helper.dart';
import 'selectable_render_widget.dart';
import 'selection.dart';
import 'selection_anchor.dart';
import 'selection_controls.dart';
import 'selection_painter.dart';
import 'selection_paragraph.dart';
import 'selections.dart';

part 'selectable_controller.dart';

/// A widget that enables text selection over all the text widgets it contains.
class Selectable extends StatefulWidget {
  /// Creates a [Selectable] widget, enabling text selection over all the text
  /// widgets it contains.
  const Selectable({
    super.key,
    required this.child,
    this.selectionColor,
    this.showSelection = true,
    this.selectWordOnLongPress = true,
    this.selectWordOnDoubleTap = false,
    this.showPopup = true,
    this.showSelectionControls = true,
    this.popupMenuItems,
    this.selectionController,
    this.scrollController,
    this.topOverlayHeight = 0,
  });

  final Widget child;
  final Color? selectionColor;
  final bool showSelection;
  final bool selectWordOnLongPress;
  final bool selectWordOnDoubleTap;
  final bool showPopup;
  final bool showSelectionControls;
  final Iterable<SelectableMenuItem>? popupMenuItems;
  final SelectableController? selectionController;
  final ScrollController? scrollController;
  final double topOverlayHeight;

  @override
  // ignore: library_private_types_in_public_api
  _SelectableState createState() => _SelectableState();
}

class _SelectableState extends State<Selectable>
    with SelectionDelegate, TickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();

  SelectableController? _selectionController;
  bool _weOwnSelCtrlr = true;
  bool get _widgetOwnsSelCtrlr => !_weOwnSelCtrlr;

  ScrollController? _scrollController;
  ScrollPosition? _scrollPosition;

  final _selections = Selections();
  final _buildHelper = SelectableBuildHelper();

  late AnimationController _selectionOpacityController;
  var _selectionIsHidden = false;
  static const _selOpacityAnimationDuration = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    updateState();

    if (_selectionController != null) {
      _selectionIsHidden = _selectionController!.getSelection()!.isHidden;
    }
    _selectionOpacityController = AnimationController(
      duration: _selOpacityAnimationDuration,
      value: _selectionIsHidden ? 0.0 : 1.0,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(Selectable oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateState();
  }

  void updateState() {
    if (_selectionController == null ||
        (!identical(_selectionController, widget.selectionController) &&
            (_widgetOwnsSelCtrlr || widget.selectionController != null))) {
      // First, remove the listener and, if we own it, dispose of the current
      // controller.
      if (_selectionController != null) {
        _selectionController!.removeListener(_selectionControllerListener);
        if (_weOwnSelCtrlr) _selectionController!.dispose();
        _selectionController = null;
      }

      // Next, save a reference to the widget's controller, or create a new
      // controller.
      if (widget.selectionController != null) {
        _selectionController = widget.selectionController;
        _weOwnSelCtrlr = false;
      } else {
        _selectionController = SelectableController();
        _weOwnSelCtrlr = true;
      }

      // And finally, call `_updateWith` and `addListener` on the new
      // controller.
      if (_selectionController != null) {
        _selectionController!
          .._updateWithSelections(_selections)
          ..addListener(_selectionControllerListener);
      }
    }
  }

  @override
  void dispose() {
    _selectionOpacityController.dispose();

    _selectionController?.removeListener(_selectionControllerListener);
    if (_weOwnSelCtrlr) _selectionController?.dispose();
    _selectionController = null;

    _removeListenerFromScrollController();

    super.dispose();
  }

  void _refresh([VoidCallback? fn]) => !mounted
      ? null
      : isBuilding
          ? WidgetsBinding.instance
              .addPostFrameCallback((timeStamp) => setState(fn ?? () {}))
          : setState(fn ?? () {});

  void _selectionControllerListener() {
    if (!mounted || _selectionController == null) return;

    final sc = _selectionController!;

    if (sc.isTextSelected &&
        (_selections.main?.isHidden ?? false) != sc.getSelection()!.isHidden) {
      // ignore: avoid_positional_boolean_parameters
      // String bToStr(bool isHidden) => isHidden ? 'hidden' : 'visible';
      // dmPrint('Selection state changed from '
      //     '${bToStr(_selections.main?.isHidden ?? false)} to '
      //     '${bToStr(sc.isHidden)}.');
      _selectionIsHidden = sc.getSelection()!.isHidden;
      if (_selectionIsHidden) {
        _selectionOpacityController.reverse();
      } else {
        _selectionOpacityController.forward();
      }
    }

    // Update [_selections] with [sc.state].
    final changed = _selections.updateWithSelections(sc._selections);
    if (changed) {
      // dmPrint('Selectable rebuilding because SelectableController updated '
      //     'the selection.');
      _refresh();
    } else if (sc._selections.isTextSelected && _buildHelper.showPopupMenu) {
      // dmPrint('Selectable rebuilding to show the popup menu.');
      _refresh();
    }
  }

  void _updateSelectionControllerWithNewSelections() {
    _selectionController?._updateWithSelections(_selections);
  }

  bool _hasChangedScrollController(ScrollController? scrollController) {
    return _scrollController != scrollController ||
        (scrollController != null &&
            (!scrollController.hasOneClient ||
                scrollController.position != _scrollPosition));
  }

  void _checkForUpdatedScrollController(ScrollController? scrollController) {
    if (_hasChangedScrollController(scrollController)) {
      _removeListenerFromScrollController();
      if (scrollController?.hasOneClient ?? false) {
        _scrollController = scrollController;
        _scrollPosition = _scrollController!.position;
        _scrollController!.position.isScrollingNotifier
            .addListener(_isScrollingListener);
        // dmPrint('Selectable: Added listener to scroll controller.');
      } else if (scrollController != null) {
        // dmPrint('Selectable: Cannot add listener, '
        //     'scrollController.hasOneClient is false.');
      }
    }
  }

  void _removeListenerFromScrollController() {
    if (_scrollPosition != null) {
      // dmPrint('Selectable: Removed listener from scroll controller.');
    }
    if (_scrollController?.hasOneClient ?? false) {
      _scrollController!.position.isScrollingNotifier
          .removeListener(_isScrollingListener);
    }
    _scrollController = null;
    _scrollPosition = null;
  }

  void _isScrollingListener() {
    if (!mounted) return;
    final isScrolling = (_scrollController?.hasOneClient ?? false) &&
        (_scrollController?.position.isScrollingNotifier.value ?? false);
    if (isScrolling != _buildHelper.isScrolling) {
      // dmPrint(isScrolling ? 'STARTED SCROLLING...' : 'STOPPED SCROLLING.');
      _buildHelper.isScrolling = isScrolling;
      if ((_selections.main?.isTextSelected ?? false) &&
          _buildHelper.showPopupMenu) {
        _refresh();
      }
    }
  }

  bool get isBuilding => _isBuilding;
  var _isBuilding = false;

  @override
  Widget build(BuildContext context) {
    _isBuilding = true;

    // Add post-frame-callback?
    if (_selectionController != null ||
        _hasChangedScrollController(widget.scrollController)) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _updateSelectionControllerWithNewSelections();
        _checkForUpdatedScrollController(widget.scrollController);
      });
    }

    if (kDebugMode || _buildHelper.controls == null) {
      _buildHelper
        ..usingCupertinoControls = _useCupertinoSelectionControls(context)
        ..controls = _buildHelper.usingCupertinoControls
            ? exCupertinoTextSelectionControls
            : exMaterialTextSelectionControls;
    }

    // Ignore taps if text is not selected, because the child might want to
    // handle them.
    final ignoreTap = !(widget.showSelectionControls &&
        (_selections.main?.isTextSelected ?? false));

    // This is how the selection color is set in the Flutter 2.5.2
    // version of src/material/selectable_text.dart, except that
    // it uses opacity of 0.40, which I think looks too dark.
    const opacity = 0.25;
    final selectionColor = widget.selectionColor ??
        TextSelectionTheme.of(context).selectionColor ??
        (_buildHelper.usingCupertinoControls
            ? CupertinoTheme.of(context).primaryColor.withOpacity(opacity)
            : Theme.of(context).colorScheme.primary.withOpacity(opacity));

    final result = Stack(
      key: _globalKey,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: widget.selectWordOnLongPress
              ? (details) => _localTapOrLongPressPt = details.localPosition
              : null,
          onLongPress: widget.selectWordOnLongPress
              ? () => _onLongPressOrDoubleTap(_localTapOrLongPressPt)
              : null,
          onTapDown: ignoreTap
              ? null
              : (details) => _localTapOrLongPressPt = details.localPosition,
          onTap: ignoreTap ? null : () => _onTap(_localTapOrLongPressPt),
          onDoubleTapDown: widget.selectWordOnDoubleTap
              ? (details) => _localTapOrLongPressPt = details.localPosition
              : null,
          onDoubleTap: widget.selectWordOnDoubleTap
              ? () => _onLongPressOrDoubleTap(_localTapOrLongPressPt)
              : null,
          child: SelectableRenderWidget(
            paragraphs: _selections.cachedParagraphs,
            selections: _selections,
            foregroundPainter: widget.showSelection
                ? _selectionController?.getCustomPainter() ??
                    DefaultSelectionPainter(
                      color: selectionColor,
                      opacityAnimation: _selectionIsHidden ==
                              (_selections.main?.isHidden ?? false)
                          ? _selectionOpacityController
                          : (_selections.main?.isHidden ?? false)
                              ? kAlwaysDismissedAnimation
                              : kAlwaysCompleteAnimation,
                    )
                : null,
            child: IgnorePointer(
              // Ignore gestures (e.g. taps) on the child if text is selected.
              ignoring: widget.showSelectionControls &&
                  (_selections.dragInfo.isSelectingWordOrDraggingHandle ||
                      (_selections.main?.isTextSelected ?? false)),
              child: widget.child,
            ),
          ),
        ),
        if (widget.showSelection &&
            (_selections.dragInfo.isSelectingWordOrDraggingHandle ||
                (_selections.main?.isTextSelected ?? false) ||
                _buildHelper.showParagraphRects))
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // If text is selected, and a handle is being dragged,
                // autoscroll if necessary.
                if ((_selections.main?.isTextSelected ?? false) &&
                    _selections.dragInfo.isDraggingHandle) {
                  final paragraphs = _selections.cachedParagraphs.list;
                  assert(paragraphs.isNotEmpty);
                  if (paragraphs.isNotEmpty) {
                    final selectionPt = _selections.dragInfo.selectionPt;
                    final maxY = paragraphs.last.rect.bottom;
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      _buildHelper.maybeAutoscroll(
                        widget.scrollController,
                        _globalKey,
                        selectionPt,
                        maxY,
                        widget.topOverlayHeight,
                      );
                    });
                  }
                }

                // dmPrint('selection.update resulted in '
                //   '${_selections.main?.rects?.length ?? 0} selection rects');
                _selections.dragInfo
                  ..selectionPt = null
                  ..handleType = null;

                if ((_selections.main?.rects?.isNotEmpty ?? false) ||
                    _buildHelper.showParagraphRects) {
                  return AnimatedOpacity(
                    opacity: (_selections.main?.isHidden ?? false) ? 0.0 : 1.0,
                    duration:
                        (_selections.main?.animationDuration ?? Duration.zero),
                    child: Stack(
                      children: [
                        // if (_selections.main.rects?.isNotEmpty ?? false)
                        //   ..._selections.main
                        //       .rects!
                        //       .map<Widget>((r) =>
                        //         _ColoredRect(rect: r, color: selectionColor))
                        //       .toList(),
                        if (widget.showSelectionControls)
                          ..._buildHelper.buildSelectionControls(
                            _selections.main,
                            context,
                            constraints,
                            this,
                            _globalKey,
                            widget.scrollController,
                            widget.topOverlayHeight,
                          ),
                        if (_buildHelper.showParagraphRects)
                          ..._selections.cachedParagraphs.list.map<Widget>(
                            (p) => _ColoredRect(
                              rect: p.rect,
                              color: Colors.yellow.withAlpha(50),
                              borderColor: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  // dmPrint('update() returned with nothing selected');

                  // IgnorePointer needs to be refreshed because
                  // _selectionPt == null now.
                  Future.delayed(Duration.zero, _refresh);

                  return const SizedBox();
                }
              },
            ),
          ),
      ],
    );

    _isBuilding = false;
    return result;
  }

  //
  // PRIVATE
  //

  Offset? _localTapOrLongPressPt;

  void _onLongPressOrDoubleTap(Offset? localPosition) {
    if (!mounted) return;
    final pt = localPosition;
    // dmPrint('onLongPressOrDoubleTap at: $pt');
    if (pt != null && !(_selections.main?.containsPoint(pt) ?? false)) {
      _refresh(() {
        if (_selections.main == null) {
          // Create the main selection object, if needed.
          _selections[0] =
              _selectionController?.getSelection() ?? const Selection();
        }
        _buildHelper.showPopupMenu = widget.showPopup;
        _selections.dragInfo
          ..selectionPt = pt
          ..handleType = null
          ..areAnchorsSwapped = false;
      });
    }
  }

  void _onTap(Offset? localPosition) {
    if (!mounted) return;
    final pt = localPosition;
    // dmPrint('onTap at: $pt');
    if (pt != null && (_selections.main?.isTextSelected ?? false)) {
      _refresh(() {
        if (_buildHelper.usingCupertinoControls &&
            (_selections.main?.containsPoint(pt) ?? false)) {
          if (widget.showPopup) {
            _buildHelper.showPopupMenu = !_buildHelper.showPopupMenu;
          }
        } else if (_selections.main != null) {
          _selections[0] = _selections.main!.cleared();
        }
      });
    }
  }

  //
  // SelectionDelegate
  //

  PointerDeviceKind? _pointerDeviceKind;

  @override
  Iterable<SelectableMenuItem> get menuItems =>
      widget.popupMenuItems ?? _defaultMenuItems;

  @override
  SelectableController? get controller => _selectionController;

  var _isDraggingSelectionHandle = false;
  var _hasDraggedAReasonableDistance = false;
  late Offset _dragStartPt;

  @override
  void onDragSelectionHandleUpdate(
    SelectionHandleType handle,
    Offset offset, {
    PointerDeviceKind? kind,
  }) {
    // dmPrint('Drag at: $offset with $handle');
    if (!mounted) return;

    if (kind != null) {
      // Save this now because it is only provided on drag-start.
      _pointerDeviceKind = kind;
    }

    // Ignore drags that are less than a reasonable distance.
    if (!_isDraggingSelectionHandle) {
      _isDraggingSelectionHandle = true;
      _hasDraggedAReasonableDistance = false;
      _dragStartPt = offset;
    } else if (!_hasDraggedAReasonableDistance) {
      final distanceSquared = (offset - _dragStartPt).distanceSquared.abs();
      // dmPrint('Drag distance squared: $distanceSquared');
      if (distanceSquared > 100) {
        _hasDraggedAReasonableDistance = true;
      }
    }

    if (_hasDraggedAReasonableDistance) {
      _refresh(() {
        // For touch, offset the y value by -30.
        final yOffset =
            _pointerDeviceKind == PointerDeviceKind.touch ? -30.0 : 0.0;

        _buildHelper.showPopupMenu = false;
        _selections.dragInfo
          ..selectionPt = Offset(offset.dx, offset.dy + yOffset)
          ..handleType = handle;
      });
    }
  }

  @override
  void onDragSelectionHandleEnd(SelectionHandleType handle) {
    // dmPrint('Drag ended with $handle, _dragInfo.areAnchorsSwapped: '
    //     '${_dragInfo.areAnchorsSwapped}');
    if (!mounted) return;

    _isDraggingSelectionHandle = false;

    // Done dragging, reset areAnchorsSwapped after next build.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _selections.dragInfo.areAnchorsSwapped = false;
    });

    if (widget.showPopup) {
      _refresh(() => _buildHelper.showPopupMenu = widget.showPopup);
    }
  }

  @override
  void hidePopupMenu() {
    if (!mounted) return;
    _refresh(() => _buildHelper.showPopupMenu = false);
  }
}

//
// PRIVATE
//

final _defaultMenuItems = [
  const SelectableMenuItem(type: SelectableMenuItemType.copy),
  const SelectableMenuItem(type: SelectableMenuItemType.define),
  const SelectableMenuItem(type: SelectableMenuItemType.webSearch)
];

bool _useCupertinoSelectionControls(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default: // android, fuchsia, etc.
      return false;
  }
}

class _ColoredRect extends StatelessWidget {
  const _ColoredRect({
    required this.rect,
    required this.color,
    this.borderColor,
  });

  final Rect rect;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: borderColor == null
                ? null
                : Border.all(
                    color: borderColor!,
                  ),
          ),
        ),
      ),
    );
  }
}
