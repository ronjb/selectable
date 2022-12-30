import 'dart:async';
import 'dart:math' as math;

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:selectable/selectable.dart';

// import 'my_selection_painter.dart';

// ignore_for_file: avoid_print

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selectable Example',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _scrollController = ScrollController();
  final _selectionController = SelectableController();
  var _isTextSelected = false;
  var _showSelection = true;
  late Timer _timer;
  List<InlineSpan> _spans = [_text];
  // List<InlineSpan> _spans = [const TextSpan(text: text1)];

  @override
  void initState() {
    super.initState();

    _selectionController
      // ..setCustomPainter(MySelectionPainter())
      // ..setCustomRectifier(SelectionRectifiers.merged)
      ..setCustomRectifier((rects) => rects
          .map((r) => Rect.fromLTRB(r.left - 2, r.top, r.right + 2, r.bottom))
          .toList())
      ..addListener(_selectionChangedListener);

    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _selectRandomWord());
  }

  @override
  void dispose() {
    _timer.cancel();
    _selectionController
      ..removeListener(_selectionChangedListener)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectionChangedListener() {
    if (_isTextSelected != _selectionController.isTextSelected) {
      if (mounted) {
        setState(() {
          _isTextSelected = _selectionController.isTextSelected;
        });
      }
    }
  }

  void _toggleShowHideSelection() {
    setState(() {
      _showSelection = !_showSelection;
      if (_showSelection) {
        _selectionController.unhide();
      } else {
        _selectionController.hide();
      }
    });
  }

  void _toggleRectifier() {
    setState(() {
      _selectionController.setCustomRectifier(
          _selectionController.getCustomRectifier() ==
                  SelectionRectifiers.identity
              ? SelectionRectifiers.merged
              : SelectionRectifiers.identity);
    });
  }

  void _selectRandomWord() {
    // final text = _selectionController.getContainedText();
    // if (text.isNotEmpty) {
    //   final i = random(max: text.length);
    //   if (_selectionController.selectWordAtIndex(i, key: 1)) {
    //     // print('selected word at $i');
    //   } else {
    //     // print('failed to select word at $i');
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverAppBar(
            pinned: true,
            collapsedHeight: kToolbarHeight,
            expandedHeight: 70,
            flexibleSpace: FlexibleSpaceBar(title: Text('Selectable Example')),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Selectable(
                selectWordOnDoubleTap: true,
                topOverlayHeight:
                    kToolbarHeight + MediaQuery.of(context).padding.top,
                selectionController: _selectionController,
                scrollController: _scrollController,
                // selectionColor: Colors.orange.withAlpha(75),
                // showSelection: _showSelection,
                popupMenuItems: [
                  SelectableMenuItem(type: SelectableMenuItemType.copy),
                  SelectableMenuItem(
                    icon: Icons.brush_outlined,
                    title: 'Color Red',
                    isEnabled: (controller) => controller!.isTextSelected,
                    handler: (controller) {
                      final selection = controller?.getSelection();
                      final startIndex = selection?.startIndex;
                      final endIndex = selection?.endIndex;
                      if (selection != null &&
                          startIndex != null &&
                          endIndex != null &&
                          endIndex > startIndex) {
                        // Split `_spans` at `startIndex`:
                        final result1 = _spans
                            .splitAtCharacterIndex(SplitAtIndex(startIndex));

                        // Split `result1.last` at `endIndex - startIndex`:
                        final result2 = result1.last.splitAtCharacterIndex(
                            SplitAtIndex(endIndex - startIndex));

                        // Update the state with the new spans.
                        setState(() {
                          _spans = [
                            if (result1.length > 1) ...result1.first,
                            TextSpan(
                              children: result2.first,
                              style: const TextStyle(color: Colors.red),
                            ),
                            if (result2.length > 1) ...result2.last,
                          ];
                        });

                        controller!.deselect();
                      }

                      return true;
                    },
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: FloatColumn(children: [TextSpan(children: _spans)]),
                ),
              ),
              childCount: 1,
            ),
          ),
        ],
      ),
      floatingActionButton: _isTextSelected
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: _toggleShowHideSelection,
                  label: Text(
                      _showSelection ? 'hide selection' : 'show selection'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  onPressed: _toggleRectifier,
                  label: const Text('switch rectifier'),
                ),
              ],
            )
          : null,
    );
  }
}

// cspell: disable

final _text = TextSpan(children: [
  const TextSpan(
    text: 'Double-tap or long press on a word to select it, '
        'then drag the selection controls to change the '
        'selection.\n\n',
    style: _headlineStyle,
  ),
  WidgetSpan(
    child: Floatable(
      float: FCFloat.end,
      clear: FCClear.both,
      padding: const EdgeInsetsDirectional.only(start: 16),
      maxWidthPercentage: 0.333,
      child: Container(height: 150, color: Colors.orange),
    ),
  ),
  const TextSpan(
    text: 'Lorem ipsum dolor\n',
    style: _headlineStyle,
  ),
  const TextSpan(text: text1, style: _textStyle2),
  const TextSpan(text: '\n\n'),
  WidgetSpan(
    child: Floatable(
      float: FCFloat.start,
      clear: FCClear.both,
      padding: const EdgeInsetsDirectional.only(end: 16),
      maxWidthPercentage: 0.333,
      child: Container(height: 150, color: Colors.blue),
    ),
  ),
  const TextSpan(
    text: 'Excepteur sint occaecat\n',
    style: _headlineStyle,
  ),
  TextSpan(children: [_span1], style: _textStyle1),
]);

const text1 = 'Lorem ipsum dolor sit amet, consectetur—adipiscing elit, sed '
    'do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim '
    'ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
    'aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit '
    'in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
    'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui '
    'officia deserunt mollit anim id est laborum.';

final _span1 = TextSpan(
  children: <InlineSpan>[
    const TextSpan(style: TextStyle(color: Colors.red), text: 'Lor'),
    const TextSpan(style: TextStyle(color: Colors.blue), text: 'em i'),
    const TextSpan(style: TextStyle(color: Colors.green), text: 'psu'),
    const TextSpan(style: TextStyle(color: Colors.red), text: 'm do'),
    const TextSpan(style: TextStyle(color: Colors.blue), text: 'lor'),
    const TextSpan(style: TextStyle(color: Colors.green), text: ' sit '),
    const TextSpan(style: TextStyle(color: Colors.red), text: 'ame'),
    const TextSpan(style: TextStyle(color: Colors.blue), text: 't, c'),
    const TextSpan(text: 'onsectetur '),
    WidgetSpan(child: Container(width: 20, height: 20, color: Colors.orange)),
    const TextSpan(text: ' adipiscing '),
    WidgetSpan(child: Container(width: 20, height: 20, color: Colors.green)),
    const TextSpan(
        text: ' elit, sed do eiusmod tempor incididunt '
            'ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis '
            'nostrud exercitation ullamco laboris nisi ut aliquip ex ea '
            'commodo consequat. Duis aute irure dolor in reprehenderit in '
            'voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
            'Excepteur sint occaecat cupidatat non proident, sunt in culpa '
            'qui officia deserunt mollit anim id est laborum.'),
  ],
);

const TextStyle _textStyle1 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.normal,
  height: 1.5,
);

const TextStyle _textStyle2 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.normal,
  height: 1.5,
  // backgroundColor: Colors.transparent,
);

const TextStyle _headlineStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w600,
);

math.Random? _random;

/// Returns a random integer uniformly distributed in the range from [min],
/// inclusive, to [max], exclusive.
int random({int min = 0, required int max}) {
  assert(max > min);
  return (_random ??= math.Random()).nextInt(math.max(0, max - min)) + min;
}

/* showDialog<void>(
  context: context,
  barrierDismissible: true,
  builder: (builder) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(16),
        child: Text(controller!.getSelection()!.text!),
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    );
  },
); */
