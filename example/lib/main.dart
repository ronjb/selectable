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
      title: 'Flutter Demo',
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

  @override
  void initState() {
    super.initState();

    _selectionController
        // ..setCustomPainter(MySelectionPainter())
        .addListener(_selectionChangedListener);

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
                    title: 'Foo! :)',
                    isEnabled: (controller) {
                      // print('SelectableMenuItem Foo, isEnabled, selected text:
                      // ${controller!.text}');
                      return controller!.isTextSelected;
                    },
                    handler: (controller) {
                      showDialog<void>(
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
                      );
                      return true;
                    },
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Double-tap or long press on a word to select it, then '
                        'drag the selection controls to change the selection.',
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      FloatColumn(
                        children: [
                          const SizedBox(height: 16),
                          Floatable(
                              float: FCFloat.end,
                              clear: FCClear.both,
                              padding:
                                  const EdgeInsetsDirectional.only(start: 16),
                              maxWidthPercentage: 0.333,
                              child:
                                  Container(height: 150, color: Colors.orange)),
                          WrappableText(
                            text: TextSpan(
                              text: 'Indent Example',
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                          const WrappableText(
                            indent: 40,
                            text: TextSpan(text: text1, style: textStyle2),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 16),
                          WrappableText(
                            text: TextSpan(
                              text: 'IgnoreSelectable Example',
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                          const IgnoreSelectable(
                            child: Text(
                              'This paragraph is wrapped in an '
                              'IgnoreSelectable widget, so it is not '
                              'selectable.',
                              style: textStyle2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Floatable(
                              float: FCFloat.start,
                              clear: FCClear.both,
                              padding: const EdgeInsetsDirectional.only(
                                  end: 16, top: 8),
                              maxWidthPercentage: 0.333,
                              child:
                                  Container(height: 150, color: Colors.blue)),
                          WrappableText(
                            text: TextSpan(
                              text: 'Hanging Indent Example',
                              style: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                          const WrappableText(
                            indent: -40,
                            padding: EdgeInsets.only(left: 40),
                            text:
                                TextSpan(children: [_span], style: textStyle1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text.rich(
                        _span,
                        style: textStyle2,
                        //style: Theme.of(context).textTheme.display1,
                      ),
                      const Text('\n\n\n'),
                    ],
                  ),
                ),
              ),
              childCount: 1,
            ),
          ),
        ],
      ),
      floatingActionButton: _isTextSelected
          ? FloatingActionButton.extended(
              onPressed: _toggleShowHideSelection,
              label: Text(_showSelection ? 'hide selection' : 'show selection'),
            )
          : null,
    );
  }
}

// cspell: disable
const text1 = 'Lorem ipsum dolor sit amet, consectetur—adipiscing elit, sed '
    'do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim '
    'ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
    'aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit '
    'in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
    'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui '
    'officia deserunt mollit anim id est laborum.';
const text2 = 'onsectetur adipiscing elit, sed do eiusmod tempor incididunt '
    'ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud '
    'exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum '
    'dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non '
    'proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

const _span = TaggedTextSpan(
  tag: 'tag',
  children: <TextSpan>[
    TextSpan(style: TextStyle(color: Colors.red), text: 'Lor'),
    TextSpan(style: TextStyle(color: Colors.blue), text: 'em i'),
    TextSpan(style: TextStyle(color: Colors.green), text: 'psu'),
    TextSpan(style: TextStyle(color: Colors.red), text: 'm do'),
    TextSpan(style: TextStyle(color: Colors.blue), text: 'lor'),
    TextSpan(style: TextStyle(color: Colors.green), text: ' sit '),
    TextSpan(style: TextStyle(color: Colors.red), text: 'ame'),
    TextSpan(style: TextStyle(color: Colors.blue), text: 't, c'),
    TextSpan(text: text2),
  ],
);

const TextStyle textStyle1 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.normal,
  height: 1.5,
);

const TextStyle textStyle2 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.normal,
  height: 1.5,
  backgroundColor: Colors.transparent,
);

math.Random? _random;

/// Returns a random integer uniformly distributed in the range from [min],
/// inclusive, to [max], exclusive.
int random({int min = 0, required int max}) {
  assert(max > min);
  return (_random ??= math.Random()).nextInt(math.max(0, max - min)) + min;
}
