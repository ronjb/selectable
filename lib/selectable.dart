// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

library selectable;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/common.dart';
import 'src/selectable_controller.dart';
import 'src/selection_controls.dart';
import 'src/selection_state.dart';
import 'src/tagged_text.dart';

export 'src/selectable_controller.dart';
export 'src/selection_controls.dart'
    show
        SelectableMenuItem,
        SelectableMenuItemType,
        SelectableMenuItemHandlerFunc;
export 'src/selection_paragraph.dart';
export 'src/tagged_text.dart';
export 'src/tagged_text_span.dart';
export 'src/tagged_widget_span.dart';

///
/// A widget that enables text selection over all the text widgets it contains.
///
class Selectable extends StatefulWidget {
  ///
  /// Creates a [Selectable] widget.
  ///
  const Selectable({
    Key? key,
    required this.child,
    this.selectionColor,
    this.showSelection = true,
    this.selectWordOnLongPress = true,
    this.selectWordOnDoubleTap = false,
    this.showPopup = true,
    this.popupMenuItems,
    this.selectionController,
    this.scrollController,
    this.topOverlayHeight = 0,
  }) : super(key: key);

  final Widget child;
  final Color? selectionColor;
  final bool showSelection;
  final bool selectWordOnLongPress;
  final bool selectWordOnDoubleTap;
  final bool showPopup;
  final Iterable<SelectableMenuItem>? popupMenuItems;
  final SelectableController? selectionController;
  final ScrollController? scrollController;
  final double topOverlayHeight;

  @override
  _SelectableState createState() => _SelectableState();
}

class _SelectableState extends State<Selectable> with SelectionDelegate {
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _childKey = GlobalKey();

  SelectableController? _selectionController;
  bool _weOwnSelCtrlr = true;
  bool get _widgetOwnsSelCtrlr => !_weOwnSelCtrlr;

  ScrollController? _scrollController;
  ScrollPosition? _scrollPosition;

  final _selection = SelectionState();

  /// The local offset of the long press, double-tap, or drag; or null if none.
  Offset? _selectionPt;

  Offset? _localTapOrLongPressPt;

  SelectionHandleType? _handleType;

  TaggedText? _start;
  TaggedText? _end;
  String? _selectedText;
  List<Rect>? _rects;

  @override
  void initState() {
    super.initState();
    update();
  }

  @override
  void didUpdateWidget(Selectable oldWidget) {
    super.didUpdateWidget(oldWidget);
    update();
  }

  void update() {
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

      // Next, save a reference to the widget's controller, or create a new controller.
      if (widget.selectionController != null) {
        _selectionController = widget.selectionController;
        _weOwnSelCtrlr = false;
      } else {
        _selectionController = SelectableController();
        _weOwnSelCtrlr = true;
      }

      // And finally, call `updateSelection` and `addListener` on the new controller.
      if (_selectionController != null) {
        _selectionController!
          ..updateSelection(_start, _end, _selectedText, _rects)
          ..addListener(_selectionControllerListener);
      }
    }
  }

  void _selectionControllerListener() {
    if (!mounted) return;
    if (_selectionController != null) {
      if (!_selectionController!.isTextSelected && _selection.isTextSelected) {
        _refresh(_selection.clear);
      } else if (_selectionController!.isTextSelected &&
          _selection.showPopupMenu) {
        // The selection changed, so the menu needs to be refreshed.
        // dmPrint('Refreshing the menu because selection changed...');
        _refresh();
      }
    }
  }

  @override
  void dispose() {
    _selectionController?.removeListener(_selectionControllerListener);
    if (_weOwnSelCtrlr) _selectionController?.dispose();
    _selectionController = null;

    _removeListenerFromScrollController();

    super.dispose();
  }

  void _refresh([VoidCallback? fn]) => mounted ? setState(fn ?? () {}) : null;

  bool _hasChangedScrollController(ScrollController? scrollController) {
    return _scrollController != scrollController ||
        (scrollController != null &&
            (!scrollController.hasClients ||
                scrollController.position != _scrollPosition));
  }

  void _checkForChangedScrollController(ScrollController? scrollController) {
    if (_hasChangedScrollController(scrollController)) {
      _removeListenerFromScrollController();
      if (scrollController?.hasClients ?? false) {
        _scrollController = scrollController;
        _scrollPosition = _scrollController!.position;
        _scrollController!.position.isScrollingNotifier
            .addListener(_isScrollingListener);
        // dmPrint('Selectable: Added listener to scroll controller.');
      } else if (scrollController != null) {
        // dmPrint('Selectable: Cannot add listener, scrollController.hasClients
        // is false.');
      }
    }
  }

  void _removeListenerFromScrollController() {
    if (_scrollPosition != null) {
      // dmPrint('Selectable: Removed listener from scroll controller.');
    }
    if (_scrollController?.hasClients ?? false) {
      _scrollController!.position.isScrollingNotifier
          .removeListener(_isScrollingListener);
    }
    _scrollController = null;
    _scrollPosition = null;
  }

  void _isScrollingListener() {
    if (!mounted) return;
    final isScrolling = (_scrollController?.hasClients ?? false) &&
        (_scrollController?.position.isScrollingNotifier.value ?? false);
    if (isScrolling != _selection.isScrolling) {
      // dmPrint(isScrolling ? 'STARTED SCROLLING...' : 'STOPPED SCROLLING.');
      _selection.isScrolling = isScrolling;
      if (_selection.isTextSelected && _selection.showPopupMenu) {
        _refresh();
      }
    }
  }

  void _onLongPressOrDoubleTap(Offset? localPosition) {
    if (!mounted) return;
    final pt = localPosition;
    // dmPrint('onLongPressOrDoubleTap at: $pt');
    if (pt != null && !_selection.containsPoint(pt)) {
      _refresh(() {
        _selection.showPopupMenu = widget.showPopup;
        _selectionPt = pt;
        _handleType = null;
      });
    }
  }

  void _onTap(Offset? localPosition) {
    if (!mounted) return;
    final pt = localPosition;
    // dmPrint('onTap at: $pt');
    if (pt != null && _selection.isTextSelected) {
      _refresh(() {
        if (_selection.usingCupertinoControls && _selection.containsPoint(pt)) {
          if (widget.showPopup) {
            _selection.showPopupMenu = !_selection.showPopupMenu;
          }
        } else {
          _selection.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add post-frame-callback?
    if (_selectionController != null ||
        _hasChangedScrollController(widget.scrollController)) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        // If the selected text changed, call `onSelectedTextChanged`.
        if (_selectionController != null &&
            (_selectedText != _selection.selectedText ||
                !areEqualLists(_rects, _selection.rects) ||
                _start != _selection.startTaggedText ||
                _end != _selection.endTaggedText)) {
          _start = _selection.startTaggedText;
          _end = _selection.endTaggedText;
          _selectedText = _selection.selectedText;
          _rects = _selection.rects == null
              ? null
              : List.of(_selection.rects!); // shallow copy
          _selectionController?.updateSelection(
              _start, _end, _selectedText, _rects);
        }

        _checkForChangedScrollController(widget.scrollController);
      });
    }

    if (kDebugMode || _selection.controls == null) {
      _selection
        ..usingCupertinoControls = _useCupertinoSelectionControls(context)
        ..controls = _selection.usingCupertinoControls
            ? exCupertinoTextSelectionControls
            : exMaterialTextSelectionControls;
    }

    // Ignore taps if text is not selected, because the child might want to handle them.
    final ignoreTap = !_selection.isTextSelected;

    return Stack(
      key: _mainKey,
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
          child: IgnorePointer(
            // Ignore gestures (e.g. taps) on the child if text is selected.
            ignoring: _selectionPt != null || _selection.isTextSelected,
            key: _childKey,
            child: widget.child,
          ),
        ),
        if (widget.showSelection &&
            (_selectionPt != null ||
                _selection.isTextSelected ||
                _selection.showParagraphRects))
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // dmPrint('Calling selection.update($_selectionPt, $_handleType)');

                final renderObject =
                    _childKey.currentContext!.findRenderObject();
                //renderObject?.layout(constraints, parentUsesSize: true);

                _selection.update(
                  renderObject,
                  _selectionPt,
                  _handleType,
                  widget.scrollController,
                  widget.topOverlayHeight,
                );

                // This is how the selection color is set in the Flutter 2.5.2
                // version of src/material/selectable_text.dart, except that
                // it uses opacity of 0.40, which I think looks too dark.
                const opacity = 0.25;
                final selectionColor = widget.selectionColor ??
                    TextSelectionTheme.of(context).selectionColor ??
                    (_selection.usingCupertinoControls
                        ? CupertinoTheme.of(context)
                            .primaryColor
                            .withOpacity(opacity)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(opacity));

                // For reference, this is how we used to set it:
                // final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                // final selectionColor = widget.selectionColor ??
                //     (isDarkMode ? Colors.blue[300]!.withAlpha(75) : Colors.blue.withAlpha(50));

                // dmPrint('selection.update resulted in ${_selection.rects?.length ?? 0} selection rects');
                _selectionPt = _handleType = null;

                if ((_selection.rects?.isNotEmpty ?? false) ||
                    _selection.showParagraphRects) {
                  return Stack(
                    children: [
                      if (_selection.rects?.isNotEmpty ?? false)
                        ..._selection.rects!
                            .map<Widget>((r) =>
                                _ColoredRect(rect: r, color: selectionColor))
                            .toList(),
                      ..._selection.buildSelectionControls(
                        context,
                        constraints,
                        this,
                        _mainKey,
                        widget.scrollController,
                        widget.topOverlayHeight,
                      ),
                      if (_selection.showParagraphRects &&
                          _selection.cachedParagraphs != null)
                        ..._selection.cachedParagraphs!
                            .map<Widget>(
                              (p) => _ColoredRect(
                                rect: p.rect,
                                color: Colors.yellow.withAlpha(50),
                                borderColor: Colors.orange,
                              ),
                            )
                            .toList(),
                    ],
                  );
                } else {
                  // dmPrint('update() returned with nothing selected');

                  // IgnorePointer needs to be refreshed, since _selectionPt == null now.
                  Future.delayed(Duration.zero, _refresh);

                  return Container();
                }
              },
            ),
          ),
      ],
    );
  }

  //
  // SelectionDelegate
  //

  @override
  Iterable<SelectableMenuItem> get menuItems =>
      widget.popupMenuItems ?? _defaultMenuItems;

  @override
  SelectableController? get controller => _selectionController;

  @override
  void onDragSelectionHandleUpdate(SelectionHandleType handle, Offset offset) {
    // dmPrint('Drag at: $offset with $handle');
    if (!mounted) return;
    _refresh(() {
      _selection.showPopupMenu = false;
      _selectionPt = offset;
      _handleType = handle;
    });
  }

  @override
  void onDragSelectionHandleEnd(SelectionHandleType handle) {
    // dmPrint('Drag ended with $handle');
    if (!mounted) return;
    _refresh(() => _selection.showPopupMenu = widget.showPopup);
  }

  @override
  void hidePopupMenu() {
    if (!mounted) return;
    _refresh(() => _selection.showPopupMenu = false);
  }
}

//
// PRIVATE STUFF
//

final _defaultMenuItems = [
  SelectableMenuItem(type: SelectableMenuItemType.copy),
  SelectableMenuItem(type: SelectableMenuItemType.define),
  SelectableMenuItem(type: SelectableMenuItemType.webSearch)
];

bool _useCupertinoSelectionControls(BuildContext context) {
  if (kIsWeb) return false;
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
    Key? key,
    required this.rect,
    required this.color,
    this.borderColor,
  }) : super(key: key);

  final Rect rect;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Container(
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
