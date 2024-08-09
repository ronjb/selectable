// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'common.dart';
import 'selection.dart';
import 'selection_painter.dart';
import 'selections.dart';

///
/// Selectable render widget
///
class SelectableRenderWidget extends SingleChildRenderObjectWidget {
  /// Creates a widget that delegates its painting.
  const SelectableRenderWidget({
    super.key,
    required this.paragraphs,
    required this.selections,
    this.painter,
    this.foregroundPainter,
    this.isComplex = false,
    this.willChange = false,
    super.child,
  })  :
        // In case this is called from non-null-safe code.
        // ignore: unnecessary_null_comparison
        assert(isComplex != null && willChange != null),
        assert(painter != null ||
            foregroundPainter != null ||
            (!isComplex && !willChange));

  /// The cached paragraphs.
  final Paragraphs paragraphs;

  /// The selections.
  final Selections selections;

  /// The painter that paints before the children.
  final SelectionPainter? painter;

  /// The painter that paints after the children.
  final SelectionPainter? foregroundPainter;

  /// Whether the painting is complex enough to benefit from caching.
  ///
  /// The compositor contains a raster cache that holds bitmaps of layers in
  /// order to avoid the cost of repeatedly rendering those layers on each
  /// frame. If this flag is not set, then the compositor will apply its own
  /// heuristics to decide whether the this layer is complex enough to benefit
  /// from caching.
  ///
  /// If both [painter] and [foregroundPainter] are null this flag is ignored.
  final bool isComplex;

  /// Whether the raster cache should be told that this painting is likely
  /// to change in the next frame.
  ///
  /// If both [painter] and [foregroundPainter] are null this flag is ignored.
  final bool willChange;

  @override
  RenderSelectableWidget createRenderObject(BuildContext context) {
    return RenderSelectableWidget(
      paragraphs: paragraphs,
      selections: selections,
      painter: painter,
      foregroundPainter: foregroundPainter,
      isComplex: isComplex,
      willChange: willChange,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSelectableWidget renderObject) {
    renderObject
      ..paragraphs = paragraphs
      ..selections = selections
      ..painter = painter
      ..foregroundPainter = foregroundPainter
      ..isComplex = isComplex
      ..willChange = willChange;
  }

  @override
  void didUnmountRenderObject(RenderSelectableWidget renderObject) {
    renderObject
      ..painter = null
      ..foregroundPainter = null;
  }
}

/// Provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [RenderSelectableWidget] first asks its [painter] to
/// paint on the current canvas, then it paints its child, and then, after
/// painting its child, it asks its [foregroundPainter] to paint. The coordinate
/// system of the canvas matches the coordinate system of the
/// [SelectableRenderWidget] object. The painters are expected to paint within a
/// rectangle starting at the origin and encompassing a region of the given
/// size. (If the painters paint outside those bounds, there might be
/// insufficient memory allocated to rasterize the painting commands and the
/// resulting behavior is undefined.)
///
/// Painters are implemented by subclassing or implementing [SelectionPainter].
///
/// Because custom paint calls its painters during paint, you cannot mark the
/// tree as needing a new layout during the callback (the layout for this frame
/// has already happened).
///
/// See also:
///  * [SelectionPainter], the class that custom painter delegates should
///    extend.
///  * [Canvas], the API provided to custom painter delegates.
class RenderSelectableWidget extends RenderProxyBox {
  /// Creates a render object that delegates its painting.
  RenderSelectableWidget({
    required Paragraphs paragraphs,
    required Selections selections,
    SelectionPainter? painter,
    SelectionPainter? foregroundPainter,
    this.isComplex = false,
    this.willChange = false,
    RenderBox? child,
  })  : _paragraphs = paragraphs,
        _selections = selections,
        _painter = painter,
        _foregroundPainter = foregroundPainter,
        super(child);

  /// The paragraphs.
  Paragraphs get paragraphs => _paragraphs;
  Paragraphs _paragraphs;

  /// Set a new paragraphs object.
  set paragraphs(Paragraphs value) {
    if (_paragraphs == value) return;
    _paragraphs = value;
    // dmPrint('RenderSelectableWidget: new paragraphs object, needs layout.');
    markNeedsLayout();
  }

  /// The selections.
  Selections get selections => _selections;
  Selections _selections;

  /// Set a new selections object.
  set selections(Selections value) {
    if (_selections != value) {
      _selections = value;

      // Reset _selectionList so it is rebuilt when needed.
      _selectionList = null;

      // dmPrint('RenderSelectableWidget: new selections, needs repaint.');
      markNeedsPaint();
    } else {
      // If the list of non-empty selections changed, need to repaint.
      final newSelectionList = value.nonEmptySelections.toList();
      if (!areEqualLists(newSelectionList, selectionList)) {
        _selectionList = newSelectionList;

        // dmPrint('RenderSelectableWidget: selection list changed, '
        //     'needs repaint.');
        markNeedsPaint();
      }
    }
  }

  /// Returns the list of non-empty selections.
  List<Selection> get selectionList =>
      _selectionList ??= selections.nonEmptySelections.toList();
  List<Selection>? _selectionList;

  /// The background custom paint delegate.
  ///
  /// This painter, if non-null, is called to paint behind the children.
  SelectionPainter? get painter => _painter;
  SelectionPainter? _painter;

  /// Set a new background custom paint delegate.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [SelectionPainter.shouldRepaint] called; if the result is
  /// `true`, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the new value is null, then there is no background custom painter.
  set painter(SelectionPainter? value) {
    if (_painter == value) {
      return;
    }
    final oldPainter = _painter;
    _painter = value;
    _didUpdatePainter(_painter, oldPainter);
  }

  /// The foreground custom paint delegate.
  ///
  /// This painter, if non-null, is called to paint in front of the children.
  SelectionPainter? get foregroundPainter => _foregroundPainter;
  SelectionPainter? _foregroundPainter;

  /// Set a new foreground custom paint delegate.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [SelectionPainter.shouldRepaint] called; if the result is
  /// `true`, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the new value is null, then there is no foreground custom painter.
  set foregroundPainter(SelectionPainter? value) {
    if (_foregroundPainter == value) {
      return;
    }
    final oldPainter = _foregroundPainter;
    _foregroundPainter = value;
    _didUpdatePainter(_foregroundPainter, oldPainter);
  }

  void _didUpdatePainter(
      SelectionPainter? newPainter, SelectionPainter? oldPainter) {
    // Check if we need to repaint.
    if (newPainter == null) {
      assert(oldPainter != null); // We should be called only for changes.
      markNeedsPaint();
    } else if (oldPainter == null ||
        newPainter.runtimeType != oldPainter.runtimeType ||
        newPainter.shouldRepaint(oldPainter)) {
      markNeedsPaint();
    }
    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newPainter?.addListener(markNeedsPaint);
    }
  }

  /// Whether to hint that this layer's painting should be cached.
  ///
  /// The compositor contains a raster cache that holds bitmaps of layers in
  /// order to avoid the cost of repeatedly rendering those layers on each
  /// frame. If this flag is not set, then the compositor will apply its own
  /// heuristics to decide whether the this layer is complex enough to benefit
  /// from caching.
  bool isComplex;

  /// Whether the raster cache should be told that this painting is likely
  /// to change in the next frame.
  bool willChange;

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child == null) return 0;
    return super.computeMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null) return 0;
    return super.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child == null) return 0;
    return super.computeMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child == null) return 0;
    return super.computeMaxIntrinsicHeight(width);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
    _foregroundPainter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    _foregroundPainter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_foregroundPainter != null &&
        (_foregroundPainter!.hitTest(position) ?? false)) {
      return true;
    }
    return super.hitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return _painter != null && (_painter!.hitTest(position) ?? true);
  }

  @override
  void performLayout() {
    super.performLayout();
    if (child != null) {
      _paragraphs.updateCachedParagraphsWithRenderBox(child!);

      // Paragraphs changed, so the selection list is no longer up-to-date.
      _selectionList = null;
    }
  }

  @override
  Size computeSizeForNoChild(BoxConstraints constraints) {
    return constraints.constrain(Size.zero);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_painter != null) {
      _paintWithPainter(context.canvas, offset, _painter!);
      _setRasterCacheHints(context);
    }
    super.paint(context, offset);
    if (_foregroundPainter != null) {
      _paintWithPainter(context.canvas, offset, _foregroundPainter!);
      _setRasterCacheHints(context);
    }
  }

  void _paintWithPainter(
      Canvas canvas, Offset offset, SelectionPainter painter) {
    late int previousCanvasSaveCount;
    canvas.save();
    assert(() {
      previousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());
    if (offset != Offset.zero) {
      canvas.translate(offset.dx, offset.dy);
    }
    for (final selection in selectionList) {
      // dmPrint('painting selection rects ${selection.rects}}');
      painter.paint(canvas, size, selection);
    }
    assert(() {
      // This isn't perfect. For example, we can't catch the case of
      // someone first restoring, then setting a transform or whatnot,
      // then saving.
      // If this becomes a real problem, we could add logic to the
      // Canvas class to lock the canvas at a particular save count
      // such that restore() fails if it would take the lock count
      // below that number.
      final canvasSaveCount = canvas.getSaveCount();
      if (canvasSaveCount > previousCanvasSaveCount) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The $painter custom painter called canvas.save() or '
            'canvas.saveLayer() at least '
            '${canvasSaveCount - previousCanvasSaveCount} more '
            'time${canvasSaveCount - previousCanvasSaveCount == 1 ? '' : 's'} '
            'than it called canvas.restore().',
          ),
          ErrorDescription(
              'This leaves the canvas in an inconsistent state and will '
              'probably result in a broken display.'),
          ErrorHint(
              'You must pair each call to save()/saveLayer() with a later '
              'matching call to restore().'),
        ]);
      }
      if (canvasSaveCount < previousCanvasSaveCount) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The $painter custom painter called canvas.restore() '
            '${previousCanvasSaveCount - canvasSaveCount} more '
            'time${previousCanvasSaveCount - canvasSaveCount == 1 ? '' : 's'} '
            'than it called canvas.save() or canvas.saveLayer().',
          ),
          ErrorDescription(
              'This leaves the canvas in an inconsistent state and will result '
              'in a broken display.'),
          ErrorHint(
              'You should only call restore() if you first called save() or '
              'saveLayer().'),
        ]);
      }
      return canvasSaveCount == previousCanvasSaveCount;
    }());
    canvas.restore();
  }

  void _setRasterCacheHints(PaintingContext context) {
    if (isComplex) {
      context.setIsComplexHint();
    }
    if (willChange) {
      context.setWillChangeHint();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(MessageProperty('painter', '$painter'))
      ..add(MessageProperty('foregroundPainter', '$foregroundPainter',
          level: foregroundPainter != null
              ? DiagnosticLevel.info
              : DiagnosticLevel.fine))
      ..add(DiagnosticsProperty<bool>('isComplex', isComplex,
          defaultValue: false))
      ..add(DiagnosticsProperty<bool>('willChange', willChange,
          defaultValue: false));
  }
}
