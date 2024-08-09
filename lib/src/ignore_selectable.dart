import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that is invisible to selection via its [Selectable] ancestor
/// widget.
///
/// When [ignoring] is true, this widget (and its subtree) is invisible to
/// its [Selectable] ancestor widget. It still consumes space during layout and
/// paints its child as usual. It just cannot be the target of text selection.
class IgnoreSelectable extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible to selection via its [Selectable]
  /// ancestor widget.
  ///
  /// The [ignoring] argument must not be null. If [ignoringSemantics] is null,
  /// this render object will be ignored for semantics if [ignoring] is true.
  const IgnoreSelectable({
    super.key,
    this.ignoring = true,
    this.ignoringSemantics,
    super.child,
  }) :
        // In case this is called from non-null-safe code.
        // ignore: unnecessary_null_comparison
        assert(ignoring != null);

  /// Whether this widget is ignored for selection via its [Selectable] ancestor
  /// widget.
  ///
  /// Regardless of whether this widget is ignored for selection, it will still
  /// consume space during layout and be visible during painting.
  final bool ignoring;

  /// Whether the semantics of this widget is ignored when compiling the
  /// semantics tree.
  ///
  /// If null, defaults to value of [ignoring].
  ///
  /// See [SemanticsNode] for additional information about the semantics tree.
  final bool? ignoringSemantics;

  @override
  RenderIgnoreSelectable createRenderObject(BuildContext context) {
    return RenderIgnoreSelectable(
      ignoring: ignoring,
      ignoringSemantics: ignoringSemantics,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderIgnoreSelectable renderObject,
  ) {
    renderObject
      ..ignoring = ignoring
      ..ignoringSemantics = ignoringSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('ignoring', ignoring))
      ..add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics,
          defaultValue: null));
  }
}

/// A render object that is invisible for to selection via its [Selectable]
/// ancestor widget.
///
/// When [ignoring] is true, this render object (and its subtree) is invisible
/// to its [Selectable] ancestor. It still consumes space during layout and
/// paints its child as usual.
///
/// When [ignoringSemantics] is true, the subtree will be invisible to the
/// semantics layer (and thus e.g. accessibility tools). If [ignoringSemantics]
/// is null, it uses the value of [ignoring].
class RenderIgnoreSelectable extends RenderProxyBox {
  RenderIgnoreSelectable({
    RenderBox? child,
    bool ignoring = true,
    bool? ignoringSemantics,
  })  : _ignoring = ignoring,
        _ignoringSemantics = ignoringSemantics,
        super(child);

  bool get ignoring => _ignoring;
  bool _ignoring;
  set ignoring(bool value) {
    if (value == _ignoring) return;
    _ignoring = value;
    if (_ignoringSemantics == null || !_ignoringSemantics!) {
      markNeedsSemanticsUpdate();
    }
  }

  bool? get ignoringSemantics => _ignoringSemantics;
  bool? _ignoringSemantics;
  set ignoringSemantics(bool? value) {
    if (value == _ignoringSemantics) {
      return;
    }
    final oldEffectiveValue = _effectiveIgnoringSemantics;
    _ignoringSemantics = value;
    if (oldEffectiveValue != _effectiveIgnoringSemantics) {
      markNeedsSemanticsUpdate();
    }
  }

  bool get _effectiveIgnoringSemantics => ignoringSemantics ?? ignoring;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && !_effectiveIgnoringSemantics) {
      visitor(child!);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('ignoring', ignoring))
      ..add(DiagnosticsProperty<bool>(
          'ignoringSemantics', _effectiveIgnoringSemantics,
          description: ignoringSemantics == null
              ? 'implicitly $_effectiveIgnoringSemantics'
              : null));
  }
}
