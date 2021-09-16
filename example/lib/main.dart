import 'package:float_column/float_column.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:selectable/selectable.dart';

// ignore_for_file: prefer_mixin, avoid_print, prefer_const_constructors, unused_element

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Counter(),
      child: MyApp(),
    ),
  );
}

class Counter with ChangeNotifier {
  int value = 0;

  void increment() {
    value += 1;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
      }
      if (_selectionController.rects != null) {
        print('selection rects: ${_selectionController.rects}');
      }
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
        title: const Text('Flutter Demo Home Page'),
      ),
      body: ListView(
        controller: _scrollController,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    print(
                        'SelectableMenuItem Foo, isEnabled, selected text: ${controller!.text}');
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
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('\n\n'),
                  const Text(
                      'The purpose of lorem ipsum is to create a natural looking block of text (sentence, paragraph, page, etc.) that doesn\'t distract from the layout. A practice not without controversy...'),
                  const Text('https://flutter.dev'),
                  const Text('You have pushed the button this many times:'),
                  Consumer<Counter>(
                    builder: (context, counter, child) => Text(
                      '${counter.value}',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                  FloatColumn(
                    children: [
                      Floatable(
                          float: FCFloat.start,
                          clear: FCClear.both,
                          clearMinSpacing: 40,
                          maxWidthPercentage: 0.333,
                          child: Container(
                            height: 200,
                            color: Colors.blue,
                            margin: Directionality.of(context) == TextDirection.ltr
                                ? const EdgeInsets.only(right: 8)
                                : const EdgeInsets.only(left: 8),
                          )),
                      const WrappableText(
                        indent: 20,
                        text: TextSpan(text: text1, style: textStyle2),
                        textAlign: TextAlign.justify,
                      ),
                      WrappableText(
                        indent: -20,
                        text: TextSpan(
                          children: [_span],
                          style: textStyle1,
                          //style: Theme.of(context).textTheme.display1,
                        ),
                      ),
                    ],
                  ),
                  Text.rich(
                    _span,
                    style: textStyle2,
                    //style: Theme.of(context).textTheme.display1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //Provider.of<Counter>(context, listen: false).increment();

          setState(() {
            _showSelection = !_showSelection;
          });

          // if (_selectionController.isTextSelected) {
          //   _selectionController.deselectAll();
          // }
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

// cspell: disable
const text1 =
    '''The purpose of lorem ipsum is to create a natural looking block of text (sentence, paragraph, page, etc.) that doesn't distract from the layout. A practice not without controversy, laying out pages with meaningless filler text can be very useful when the focus is meant to be on design, not content.''';
const text2 =
    '''orem ipsum is to create a natural looking block of text (sentence, paragraph, page, etc.) that doesn't distract from the layout. A practice not without controversy, laying out pages with meaningless filler text can be very useful when the focus is meant to be on design, not content.''';

final _span = TaggedTextSpan(
  tag: 'tag',
  children: <TextSpan>[
    TextSpan(style: TextStyle(color: Colors.red), text: 'T'),
    TextSpan(style: TextStyle(color: Colors.blue), text: 'h'),
    TextSpan(style: TextStyle(color: Colors.green), text: 'e'),
    TextSpan(style: TextStyle(color: Colors.green), text: ' '),
    TextSpan(style: TextStyle(color: Colors.red), text: 'pu'),
    TextSpan(style: TextStyle(color: Colors.blue), text: 'rp'),
    TextSpan(style: TextStyle(color: Colors.green), text: 'ose '),
    TextSpan(style: TextStyle(color: Colors.red), text: 'o'),
    TextSpan(style: TextStyle(color: Colors.blue), text: 'f '),
    TextSpan(style: TextStyle(color: Colors.green), text: 'l'),
    const TextSpan(style: TextStyle(color: Colors.black), text: text2),
    TextSpan(style: textStyle2.copyWith(color: Colors.green), text: ' Abcdefg'),
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
