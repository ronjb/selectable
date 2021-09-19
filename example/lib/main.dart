import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:selectable/selectable.dart';

// ignore_for_file: prefer_mixin, avoid_print, prefer_const_constructors, unused_element

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _scrollController = ScrollController();
  final _selectionController = SelectableController();
  var _isTextSelected = false;

  @override
  void initState() {
    super.initState();
    _selectionController.addListener(() {
      if (_isTextSelected != _selectionController.isTextSelected) {
        _isTextSelected = _selectionController.isTextSelected;
        print(_isTextSelected ? 'Text is selected' : 'Text is not selected');
        if (mounted) setState(() {});
      }
      // if (_selectionController.rects != null) {
      //   print('selection rects: ${_selectionController.rects}');
      // }
    });
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  var _showSelection = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selectable Example'),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Selectable(
          selectionController: _selectionController,
          scrollController: _scrollController,
          selectionColor: Colors.orange.withAlpha(75),
          showSelection: _showSelection,
          showPopup: true,
          popupMenuItems: [
            SelectableMenuItem(type: SelectableMenuItemType.copy),
            SelectableMenuItem(
              title: 'Foo! :)',
              isEnabled: (controller) {
                print('SelectableMenuItem Foo, isEnabled, selected text: ${controller!.text}');
                return controller.isTextSelected;
              },
              handler: (controller) {
                showDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  builder: (builder) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.zero,
                      content: Container(
                        padding: EdgeInsets.all(16),
                        child: Text(controller!.text!),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  'Long press on a word to select it, then drag the selection controls to change the selection.',
                  style: Theme.of(context).textTheme.headline5,
                ),
                FloatColumn(
                  children: [
                    const SizedBox(height: 16),
                    Floatable(
                        float: FCFloat.end,
                        clear: FCClear.both,
                        padding: EdgeInsetsDirectional.only(start: 16),
                        maxWidthPercentage: 0.333,
                        child: Container(height: 150, color: Colors.orange)),
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
                    Floatable(
                        float: FCFloat.start,
                        clear: FCClear.both,
                        padding: EdgeInsetsDirectional.only(end: 16, top: 8),
                        maxWidthPercentage: 0.333,
                        child: Container(height: 150, color: Colors.blue)),
                    WrappableText(
                      text: TextSpan(
                        text: 'Hanging Indent Example',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ),
                    WrappableText(
                      indent: -40,
                      padding: const EdgeInsets.only(left: 40),
                      text: const TextSpan(children: [_span], style: textStyle1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text.rich(
                  _span,
                  style: textStyle2,
                  //style: Theme.of(context).textTheme.display1,
                ),
                Text('\n\n\n\n\n\n\n\n'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isTextSelected
          ? FloatingActionButton.extended(
              onPressed: () {
                //Provider.of<Counter>(context, listen: false).increment();

                setState(() {
                  _showSelection = !_showSelection;
                });

                // if (_selectionController.isTextSelected) {
                //   _selectionController.deselectAll();
                // }
              },
              //tooltip: 'Increment',
              //child: Icon(Icons.add),
              label: Text(_showSelection ? 'hide selection' : 'show selection'),
            )
          : null,
    );
  }
}

// cspell: disable
const text1 =
    '''Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.''';
const text2 =
    '''onsectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.''';

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
    TextSpan(style: TextStyle(color: Colors.black), text: text2),
    // TextSpan(style: textStyle2.copyWith(color: Colors.green), text: ' Abcdefg'),
  ],
);

const TextStyle textStyle1 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.normal,
  height: 1.5,
  color: Colors.black,
  backgroundColor: Color(0xFFEEEEEE),
);

const TextStyle textStyle2 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.normal,
  height: 1.5,
  color: Colors.black,
  backgroundColor: Colors.transparent,
);
