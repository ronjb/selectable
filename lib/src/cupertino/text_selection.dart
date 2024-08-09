// Adapted from flutter/lib/src/cupertino/text_selection.dart

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../selectable.dart';
import '../selection_controls.dart';

// The original file ignores these lints.
// ignore_for_file: avoid_positional_boolean_parameters
// ignore_for_file: avoid_setters_without_getters, omit_local_variable_types
// ignore_for_file: avoid_as, cascade_invocations
// ignore_for_file: avoid_types_on_closure_parameters

/// Text selection controls that follows iOS design conventions.
final SelectionControls exCupertinoTextSelectionControls =
    _CupertinoTextSelectionControls();

// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleOverlap = 1.5;
// Extracted from https://developer.apple.com/design/resources/.
const double _kSelectionHandleRadius = 6;

// Minimal padding from all edges of the selection popup menu to all edges of
// the screen.
const double _kPopupMenuScreenPadding = 8.0;
// Minimal padding from tip of the selection popup menu arrow to horizontal
// edges of the screen. Eyeballed value.
const double _kArrowScreenPadding = 26.0;

// Vertical distance between the tip of the arrow and the line of text the arrow
// is pointing to. The value used here is eyeballed.
const double _kPopupMenuContentDistance = 8.0;
// Values derived from https://developer.apple.com/design/resources/.
// 92% Opacity ~= 0xEB

// Values extracted from https://developer.apple.com/design/resources/.
// The height of the popup menu, including the arrow.
const double _kPopupMenuHeight = 43.0;
const Size _kPopupMenuArrowSize = Size(14.0, 7.0);
const Radius _kPopupMenuBorderRadius = Radius.circular(8);
// Colors extracted from https://developer.apple.com/design/resources/.
// TO-DO: https://github.com/flutter/flutter/issues/41507.
const Color _kPopupMenuBackgroundColor = Color(0xEB202020);
const Color _kPopupMenuDividerColor = Color(0xFF808080);

const TextStyle _kPopupMenuButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.white,
);

// Eyeballed value.
const EdgeInsets _kPopupMenuButtonPadding =
    EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);

/// An iOS-style popup menu that appears in response to text selection.
///
/// Typically displays buttons for copying text.
///
/// See also:
///
///  * [SelectionControls.buildPopupMenu], where
///    [_CupertinoTextSelectionPopupMenu] will be used to build an iOS-style
///    popup menu.
class _CupertinoTextSelectionPopupMenu extends SingleChildRenderObjectWidget {
  const _CupertinoTextSelectionPopupMenu._({
    double? barTopY,
    double? arrowTipX,
    bool? isArrowPointingDown,
    super.child,
  })  : _barTopY = barTopY,
        _arrowTipX = arrowTipX,
        _isArrowPointingDown = isArrowPointingDown;

  // The y-coordinate of popup menu's top edge, in global coordinate system.
  final double? _barTopY;

  // The y-coordinate of the tip of the arrow, in global coordinate system.
  final double? _arrowTipX;

  // Whether the arrow should point down and be attached to the bottom
  // of the popup menu, or point up and be attached to the top of the popup
  // menu.
  final bool? _isArrowPointingDown;

  @override
  _PopupMenuRenderBox createRenderObject(BuildContext context) =>
      _PopupMenuRenderBox(_barTopY, _arrowTipX, _isArrowPointingDown, null);

  @override
  void updateRenderObject(
      BuildContext context, _PopupMenuRenderBox renderObject) {
    renderObject
      ..barTopY = _barTopY
      ..arrowTipX = _arrowTipX
      ..isArrowPointingDown = _isArrowPointingDown;
  }
}

class _PopupMenuParentData extends BoxParentData {
  // The x offset from the tip of the arrow to the center of the popup menu.
  // Positive if the tip of the arrow has a larger x-coordinate than the
  // center of the popup menu.
  late double arrowXOffsetFromCenter;
  @override
  String toString() =>
      'offset=$offset, arrowXOffsetFromCenter=$arrowXOffsetFromCenter';
}

class _PopupMenuRenderBox extends RenderShiftedBox {
  _PopupMenuRenderBox(
    this._barTopY,
    this._arrowTipX,
    this._isArrowPointingDown,
    RenderBox? child,
  ) : super(child);

  @override
  bool get isRepaintBoundary => true;

  double? _barTopY;
  set barTopY(double? value) {
    if (_barTopY == value) {
      return;
    }
    _barTopY = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double? _arrowTipX;
  set arrowTipX(double? value) {
    if (_arrowTipX == value) {
      return;
    }
    _arrowTipX = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool? _isArrowPointingDown;
  set isArrowPointingDown(bool? value) {
    if (_isArrowPointingDown == value) {
      return;
    }
    _isArrowPointingDown = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  final BoxConstraints heightConstraint =
      const BoxConstraints.tightFor(height: _kPopupMenuHeight);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _PopupMenuParentData) {
      child.parentData = _PopupMenuParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    if (child == null) {
      return;
    }
    final BoxConstraints enforcedConstraint = constraints
        .deflate(
            const EdgeInsets.symmetric(horizontal: _kPopupMenuScreenPadding))
        .loosen();

    child!.layout(
      heightConstraint.enforce(enforcedConstraint),
      parentUsesSize: true,
    );
    final _PopupMenuParentData childParentData =
        (child!.parentData as _PopupMenuParentData?)!;

    // The local x-coordinate of the center of the popup menu.
    final double lowerBound = child!.size.width / 2 + _kPopupMenuScreenPadding;
    final double upperBound =
        size.width - child!.size.width / 2 - _kPopupMenuScreenPadding;
    final double adjustedCenterX = _arrowTipX!.clamp(lowerBound, upperBound);

    childParentData.offset =
        Offset(adjustedCenterX - child!.size.width / 2, _barTopY!);
    childParentData.arrowXOffsetFromCenter = _arrowTipX! - adjustedCenterX;
  }

  // The path is described in the popup menu's coordinate system.
  Path _clipPath() {
    final _PopupMenuParentData childParentData =
        (child!.parentData as _PopupMenuParentData?)!;
    final Path rrect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(
                0,
                _isArrowPointingDown! ? 0 : _kPopupMenuArrowSize.height,
              ) &
              Size(child!.size.width,
                  child!.size.height - _kPopupMenuArrowSize.height),
          _kPopupMenuBorderRadius,
        ),
      );

    final double arrowTipX =
        child!.size.width / 2 + childParentData.arrowXOffsetFromCenter;

    final double arrowBottomY = _isArrowPointingDown!
        ? child!.size.height - _kPopupMenuArrowSize.height
        : _kPopupMenuArrowSize.height;

    final double arrowTipY = _isArrowPointingDown! ? child!.size.height : 0;

    final Path arrow = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowTipX - _kPopupMenuArrowSize.width / 2, arrowBottomY)
      ..lineTo(arrowTipX + _kPopupMenuArrowSize.width / 2, arrowBottomY)
      ..close();

    return Path.combine(PathOperation.union, rrect, arrow);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final _PopupMenuParentData childParentData =
        (child!.parentData as _PopupMenuParentData?)!;
    context.pushClipPath(
      needsCompositing,
      offset + childParentData.offset,
      Offset.zero & child!.size,
      _clipPath(),
      (PaintingContext innerContext, Offset innerOffset) =>
          innerContext.paintChild(child!, innerOffset),
    );
  }

  Paint? _debugPaint;

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child == null) {
        return true;
      }

      _debugPaint ??= Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(10.0, 10.0),
          <Color>[
            const Color(0x00000000),
            const Color(0xFFFF00FF),
            const Color(0xFFFF00FF),
            const Color(0x00000000)
          ],
          <double>[0.25, 0.25, 0.75, 0.75],
          TileMode.repeated,
        )
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final _PopupMenuParentData childParentData =
          (child!.parentData as _PopupMenuParentData?)!;
      context.canvas.drawPath(
          _clipPath().shift(offset + childParentData.offset), _debugPaint!);
      return true;
    }());
  }
}

/// Draws a single text selection handle with a bar and a ball.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      _kSelectionHandleRadius,
      paint,
    );
    // Draw line so it slightly overlaps the circle.
    canvas.drawLine(
      const Offset(
        _kSelectionHandleRadius,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(
        _kSelectionHandleRadius,
        size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) =>
      color != oldPainter.color;
}

class _CupertinoTextSelectionControls extends SelectionControls {
  /// Returns the size of the Cupertino handle.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for iOS-style copy/paste text selection popup menu.
  @override
  Widget buildPopupMenu(
    BuildContext context,
    Rect viewport,
    List<Rect>? selectionRects,
    SelectionDelegate delegate,
    double topOverlayHeight,
    bool useExperimentalPopupMenu,
  ) {
    assert(debugCheckHasMediaQuery(context));
    final padding = MediaQuery.paddingOf(context);

    // TextSelectionPoint(rects.first.bottomLeft, TextDirection.ltr),
    // TextSelectionPoint(rects.last.bottomRight, TextDirection.ltr)

    final double popupMenuHeightNeeded = padding.top +
        _kPopupMenuScreenPadding +
        _kPopupMenuHeight +
        _kPopupMenuContentDistance;

    final primaryY = math.min(
        viewport.bottom -
            (_kPopupMenuContentDistance * 2.0) -
            _kPopupMenuHeight,
        selectionRects!.first.top -
            _kPopupMenuContentDistance -
            _kPopupMenuHeight);

    double? secondaryY;

    // Will fit below?
    if (viewport.bottom - selectionRects.last.bottom >= popupMenuHeightNeeded) {
      secondaryY = math.max(viewport.top + _kPopupMenuContentDistance,
          selectionRects.last.bottom + _kPopupMenuContentDistance);
    }

    // Else, show in center.
    else {
      secondaryY = viewport.center.dy - (_kPopupMenuHeight / 2.0);
    }

    final double arrowTipX =
        ((selectionRects.last.left + selectionRects.first.right) / 2.0).clamp(
      _kArrowScreenPadding + padding.left,
      MediaQuery.sizeOf(context).width - padding.right - _kArrowScreenPadding,
    );

    if (useExperimentalPopupMenu) {
      // print('building menu at $arrowTipX, $localBarTopY');
      return delegate.buildMenu(
        context,
        primaryAnchor: Offset(arrowTipX, primaryY + topOverlayHeight - 40),
        secondaryAnchor: Offset(arrowTipX, secondaryY),
      );
    }

    var isArrowPointingDown = true;
    var localBarTopY = 0.0;

    // Will fit above?
    if (selectionRects.first.top - viewport.top >= popupMenuHeightNeeded) {
      localBarTopY = primaryY;
    } else

    // Will fit below?
    if (viewport.bottom - selectionRects.last.bottom >= popupMenuHeightNeeded) {
      localBarTopY = secondaryY;
      isArrowPointingDown = false;
    }

    // Else, show in center.
    else {
      localBarTopY = secondaryY;
    }

    final List<Widget> items = <Widget>[];
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.devicePixelRatioOf(context));
    final EdgeInsets arrowPadding = isArrowPointingDown
        ? EdgeInsets.only(bottom: _kPopupMenuArrowSize.height)
        : EdgeInsets.only(top: _kPopupMenuArrowSize.height);

    // dmPrint('_CupertinoTextSelectionControls.buildPopupMenu');

    void addPopupMenuButtonIfNeeded(
      IconData? icon,
      String text,
      bool Function(SelectableController?) predicate,
      bool Function(SelectableController?)? onPressed,
    ) {
      if (!predicate(delegate.controller)) {
        // dmPrint('NOT showing $text menu because isEnabled returned `false`');
        return;
      }

      if (items.isNotEmpty) {
        items.add(onePhysicalPixelVerticalDivider);
      }

      Widget textWidget() => MediaQuery.withNoTextScaling(
            child: Text(
              icon == null ? text : ' $text',
              style: _kPopupMenuButtonFontStyle,
            ),
          );

      items.add(CupertinoButton(
        color: _kPopupMenuBackgroundColor,
        minSize: _kPopupMenuHeight,
        padding: _kPopupMenuButtonPadding.add(arrowPadding),
        borderRadius: null,
        pressedOpacity: 0.7,
        onPressed: () => onPressed!(delegate.controller),
        child: icon == null
            ? textWidget()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18.0,
                    color: const Color(0xffffffff),
                  ),
                  textWidget(),
                ],
              ),
      ));
    }

    for (final item in delegate.menuItems) {
      addPopupMenuButtonIfNeeded(
          item.icon, item.title ?? '', item.isEnabled!, item.handler);
    }

    return _CupertinoTextSelectionPopupMenu._(
      barTopY: localBarTopY,
      arrowTipX: arrowTipX,
      isArrowPointingDown: isArrowPointingDown,
      child: items.isEmpty
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(color: _kPopupMenuDividerColor),
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = getHandleSize(textLineHeight);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
            CupertinoTheme.of(context).primaryColor),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        return handle;
      case TextSelectionHandleType.right:
        // Right handle is a vertical mirror of the left.
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return const SizedBox();
    }
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [SelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final Size handleSize = getHandleSize(textLineHeight);
    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        return Offset(
          handleSize.width / 2,
          handleSize.height -
              2 * _kSelectionHandleRadius +
              _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      default:
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}
