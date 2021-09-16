import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:selectable/src/common.dart';

// ignore_for_file: prefer_const_constructors
// cspell: disable

Rect r(double left, double top, double right, double bottom) =>
    Rect.fromLTRB(left, top, right, bottom);

extension _ExtOnIterableOfRect on Iterable<Rect> {
  List<Rect> mtsr() => mergedToSelectionRects();
}

void main() {
  test('mergedToSelectionRects', () {
    var rects = [r(0, 0, 1, 1)];
    expect(rects.mtsr(), [r(0, 0, 1, 1)]);

    //   012345
    // 0 ┌┐        ┌┐
    // 1 └┘┌┐  =>  └┘┌┐
    // 2   └┘        └┘
    rects = [r(0, 0, 1, 1), r(2, 1, 3, 2)];
    expect(rects.mtsr(), [r(0, 0, 1, 1), r(2, 1, 3, 2)]);

    //   012345       012345
    // 0 ┌┐           ┌────┐
    // 1 └┘┌┐    =>   ├────┤
    // 2   └┘┌┐       ├────┤
    // 3     └┘       └────┘
    rects = [r(0, 0, 1, 1), r(2, 1, 3, 2), r(4, 2, 5, 3)];
    expect(rects.mtsr(), [r(0, 0, 5, 1), r(0, 1, 5, 2), r(0, 2, 5, 3)]);

    //   012345       012345
    // 0     ┌┐           ┌┐
    // 1   ┌┐└┘  =>   ┌───┴┤
    // 2 ┌┐└┘         ├┬───┘
    // 3 └┘           └┘
    rects = [r(4, 0, 5, 1), r(2, 1, 3, 2), r(0, 2, 1, 3)];
    expect(rects.mtsr(), [r(4, 0, 5, 1), r(0, 1, 5, 2), r(0, 2, 1, 3)]);

    //   01234567      01234567
    // 0 ┌┐┌┐          ┌────┐
    // 1 └┘││          │    │
    // 3   ││      =>  │    │
    // 4   ││┌┐        │    │
    // 5   └┘└┘┌┐      └────┘┌┐
    // 6       └┘            └┘
    rects = [r(0, 0, 1, 1), r(2, 0, 3, 5), r(4, 4, 5, 5), r(6, 5, 7, 6)];
    expect(rects.mtsr(), [r(0, 0, 5, 5), r(6, 5, 7, 6)]);

    //   01234567      01234567
    // 0 ┌┐            ┌┐
    // 1 └┘  ┌┐┌┐      └┘┌────┐
    // 2     ││└┘        │    │
    // 3     ││      =>  │    │
    // 4   ┌┐││          │    │
    // 5   └┘└┘          └────┘
    rects = [r(0, 0, 1, 1), r(2, 4, 3, 5), r(4, 1, 5, 5), r(6, 1, 7, 2)];
    expect(rects.mtsr(), [r(0, 0, 1, 1), r(2, 1, 7, 5)]);
  });
}
