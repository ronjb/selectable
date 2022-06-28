// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import 'common.dart';
import 'selectable.dart';

export 'cupertino/text_selection.dart';
export 'material/text_selection.dart';

// ignore_for_file: omit_local_variable_types
// ignore_for_file: cascade_invocations

/// An interface for building the selection UI, to be provided by the
/// implementor of the popup menu widget.
abstract class SelectionControls {
  // Adapted from TextSelectionControls in
  // flutter/lib/src/widgets/text_selection.dart

  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight);

  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight);

  Widget buildPopupMenu(
    BuildContext context,
    Rect viewport,
    List<Rect>? selectionRects,
    SelectionDelegate delegate,
  );

  /// Returns the size of the selection handle.
  Size getHandleSize(double textLineHeight);
}

enum SelectionHandleType { left, right }

mixin SelectionDelegate {
  void onDragSelectionHandleUpdate(SelectionHandleType handle, Offset offset,
      {PointerDeviceKind? kind}) {}
  void onDragSelectionHandleEnd(SelectionHandleType handle) {}
  SelectableController? get controller;
  Iterable<SelectableMenuItem> get menuItems;
  void hidePopupMenu() {}
}

enum SelectableMenuItemType { copy, define, webSearch, other }

typedef SelectableMenuItemHandlerFunc = bool Function(
    SelectableController? controller);

@immutable
class SelectableMenuItem {
  const SelectableMenuItem({
    this.type = SelectableMenuItemType.other,
    String? title,
    SelectableMenuItemHandlerFunc? isEnabled,
    SelectableMenuItemHandlerFunc? handler,
  })  : assert(type != null && // ignore: unnecessary_null_comparison
            (type != SelectableMenuItemType.other ||
                (title != null && isEnabled != null && handler != null))),
        title = title ??
            (type == SelectableMenuItemType.copy
                ? 'Copy'
                : type == SelectableMenuItemType.define
                    ? 'Define'
                    : type == SelectableMenuItemType.webSearch
                        ? 'WebSearch'
                        : null),
        isEnabled = isEnabled ??
            (type == SelectableMenuItemType.copy
                ? _canCopy
                : type == SelectableMenuItemType.define
                    ? _canDefine
                    : type == SelectableMenuItemType.webSearch
                        ? _canWebSearch
                        : null),
        handler = handler ??
            (type == SelectableMenuItemType.copy
                ? _handleCopy
                : type == SelectableMenuItemType.define
                    ? _handleDefine
                    : type == SelectableMenuItemType.webSearch
                        ? _handleWebSearch
                        : null);

  final SelectableMenuItemType type;
  final String? title;
  final SelectableMenuItemHandlerFunc? isEnabled;
  final SelectableMenuItemHandlerFunc? handler;
}

//
// PRIVATE
//

// ignore: prefer_function_declarations_over_variables
bool _canCopy(SelectableController? controller) {
  return controller?.isTextSelected ?? false;
}

bool _handleCopy(SelectableController? controller) {
  if (controller?.isTextSelected ?? false) {
    Clipboard.setData(ClipboardData(text: _selectedText(controller)));
    controller?.deselectAll();
    return true;
  }
  return false;
}

bool _canDefine(SelectableController? controller) {
  final text = _selectedText(controller);
  if (text.isNotEmpty && (!text.contains(' ') || text.split(' ').length <= 2)) {
    return true;
  }
  return false;
}

bool _handleDefine(SelectableController? controller) {
  final text = _selectedText(controller);
  if (text.isNotEmpty) {
    final url = _search(text, define: true);
    // delegate.hidePopupMenu();
    _launchBrowserWithUrl(url);
    return true;
  }
  return false;
}

bool _canWebSearch(SelectableController? controller) {
  return _selectedText(controller).isNotEmpty;
}

bool _handleWebSearch(SelectableController? controller) {
  final text = _selectedText(controller);
  if (text.isNotEmpty) {
    final url = _search(text);
    _launchBrowserWithUrl(url);
    return true;
  }
  return false;
}

String _selectedText(SelectableController? controller) {
  return controller?.getSelection()?.text?.trim() ?? '';
}

Future<void> _launchBrowserWithUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    }
  }
  // ignore: avoid_catches_without_on_clauses
  catch (e) {
    dmPrint('WARNING: Selectable is unable to launch the browser with '
        'url "$url": $e');
  }
}

String _search(String text, {bool define = false}) {
  if (text.toLowerCase().startsWith('http')) {
    return text;
  }

  //return _duckDuckGoSearch(text, define: define);
  return _googleSearch(text, define: define);
}

String _googleSearch(String text, {bool define = false}) {
  final params = <String, dynamic>{'q': define ? 'define $text' : text};
  return Uri(
    scheme: 'https',
    host: 'google.com',
    path: 'search',
    queryParameters: params,
  ).toString();
}

// ignore: unused_element
String _duckDuckGoSearch(String text, {bool define = false}) {
  final params = <String, dynamic>{
    'q': text,
    if (define) 'ia': 'definition',
  };
  return Uri(
    scheme: 'https',
    host: 'duckduckgo.com',
    queryParameters: params,
  ).toString();
}
