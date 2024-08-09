// Adapted from flutter/lib/src/material/text_selection.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../selection_controls.dart';

// The original file ignores these lints.
// ignore_for_file: omit_local_variable_types
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: cascade_invocations, prefer_const_constructors

/// Text selection controls that follow the Material Design specification.
final SelectionControls exMaterialTextSelectionControls =
    _MaterialTextSelectionControls();

const double _kHandleSize = 22.0;
const double _kButtonPadding = 10.0;

// Minimal padding from all edges of the selection popup menu to all edges of
// the viewport.
const double _kPopupMenuScreenPadding = 8.0;
const double _kPopupMenuHeight = 44.0;
const double _kPopupMenuContentDistance = 8.0;

/// Manages a copy/paste text selection popup menu.
class _TextSelectionPopupMenu extends StatelessWidget {
  const _TextSelectionPopupMenu({this.delegate});

  final SelectionDelegate? delegate;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    //final localizations = MaterialLocalizations.of(context);
    final items = delegate!.menuItems
        .expand<Widget>((e) => e.isEnabled!(delegate!.controller)
            ? [
                _Button(
                  icon: e.icon,
                  title: e.title ?? '',
                  isDarkMode: isDarkMode,
                  onPressed: () => e.handler!(delegate!.controller),
                )
              ]
            : [])
        .toList();

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      // dmPrint('_TextSelectionPopupMenu is not showing because '
      //     'items.isEmpty.');
      return SizedBox.shrink();
    }

    return Material(
      elevation: 4.0,
      color: Theme.of(context).canvasColor,
      borderRadius: BorderRadius.circular(8),
      child: Theme(
        data: ThemeData(buttonTheme: ButtonThemeData(minWidth: 0)),
        child: Container(
          height: _kPopupMenuHeight,
          padding: EdgeInsets.symmetric(horizontal: _kButtonPadding),
          child: Row(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ),
    );
  }
}

const TextStyle popupMenuTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.title,
    required this.isDarkMode,
    required this.onPressed,
  });

  final IconData? icon;
  final String title;
  final bool? isDarkMode;
  final void Function()? onPressed;

  Widget get _text => Text(
        icon == null ? title : ' $title',
        style: popupMenuTextStyle.copyWith(
            color: isDarkMode! ? Colors.white : Colors.black),
      );

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: _kButtonPadding)),
        onPressed: onPressed,
        child: icon == null
            ? _text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20.0 *
                        (MediaQuery.textScalerOf(context).scale(18) / 18.0),
                    color: isDarkMode! ? Colors.white : Colors.black,
                  ),
                  _text,
                ],
              ),
      );
}

/// Centers the popup menu around the given position, ensuring that it remains
/// on screen.
class _TextSelectionPopupMenuLayout extends SingleChildLayoutDelegate {
  const _TextSelectionPopupMenuLayout(this.maxWidth, this.position);

  /// The size of the screen at the time that the popup menu was last laid out.
  final double maxWidth;

  /// Anchor position of the popup menu.
  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Offset globalPosition = position;

    var x = globalPosition.dx - childSize.width / 2.0;
    final y = globalPosition.dy - childSize.height;

    if (x < _kPopupMenuScreenPadding)
      x = _kPopupMenuScreenPadding;
    else if (x + childSize.width > maxWidth - _kPopupMenuScreenPadding)
      x = maxWidth - childSize.width - _kPopupMenuScreenPadding;

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TextSelectionPopupMenuLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter({this.color});

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color!;
    final double radius = size.width / 2.0;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, radius, radius), paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

class _MaterialTextSelectionControls extends SelectionControls {
  /// Returns the size of the Material handle.
  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(_kHandleSize, _kHandleSize);

  /// Builder for material-style copy/paste text selection popup menu.
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
    assert(debugCheckHasMaterialLocalizations(context));

    const double popupMenuHeightNeeded = _kPopupMenuScreenPadding +
        _kPopupMenuHeight +
        _kPopupMenuContentDistance;

    final primaryY = math.min(
        viewport.bottom - (_kPopupMenuContentDistance * 3.0),
        selectionRects!.first.top - _kPopupMenuContentDistance);

    double? secondaryY;

    // Will fit below?
    if (viewport.bottom - selectionRects.last.bottom >=
        _kHandleSize + _kPopupMenuHeight + _kPopupMenuContentDistance) {
      secondaryY = math.max(
          viewport.top + _kPopupMenuContentDistance + _kPopupMenuHeight,
          selectionRects.last.bottom +
              _kHandleSize +
              _kPopupMenuHeight +
              _kPopupMenuContentDistance);
    }

    // Show in center.
    else {
      secondaryY = viewport.center.dy;
    }

    final arrowTipX =
        (selectionRects.last.left + selectionRects.first.right) / 2.0;

    if (useExperimentalPopupMenu) {
      // print('building menu at $arrowTipX, $localBarTopY');
      return delegate.buildMenu(
        context,
        primaryAnchor: Offset(arrowTipX, primaryY + topOverlayHeight - 70),
        secondaryAnchor: Offset(arrowTipX, secondaryY),
      );
    }

    var localBarTopY = 0.0;
    if (selectionRects.first.top - viewport.top >= popupMenuHeightNeeded) {
      localBarTopY = primaryY;
    } else {
      localBarTopY = secondaryY;
    }

    final Offset preciseMidpoint = Offset(arrowTipX, localBarTopY);

    return CustomSingleChildLayout(
      delegate: _TextSelectionPopupMenuLayout(
        viewport.width,
        preciseMidpoint,
      ),
      child: _TextSelectionPopupMenu(delegate: delegate),
    );
  }

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textHeight) {
    final ThemeData theme = Theme.of(context);
    final Color handleColor =
        TextSelectionTheme.of(context).selectionHandleColor ??
            theme.colorScheme.primary;
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          color: handleColor,
        ),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return Transform.rotate(
          angle: math.pi / 2.0,
          child: handle,
        );
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return Transform.rotate(
          angle: math.pi / 4.0,
          child: handle,
        );
    }
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// See [SelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, 0);
      case TextSelectionHandleType.right:
        return Offset.zero;
      default:
        return const Offset(_kHandleSize / 2, -4);
    }
  }
}
