// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/src/inline_span_ext.dart';

void main() {
  group('visitChildrenEx', () {
    test('forwards includesPlaceholders to recursive calls', () {
      // A TextSpan with a child WidgetSpan (placeholder).
      const span = TextSpan(
        text: 'Hello',
        children: [
          WidgetSpan(child: SizedBox()),
          TextSpan(text: ' World'),
        ],
      );

      // With includesPlaceholders = true (default), the WidgetSpan should
      // increment the index by 1.
      final indicesWithPlaceholders = <int>[];
      span.visitChildrenEx((span, index) {
        indicesWithPlaceholders.add(index);
        return true;
      }, includesPlaceholders: true);
      // 'Hello' at 0, WidgetSpan at 5, ' World' at 6.
      expect(indicesWithPlaceholders, [0, 5, 6]);

      // With includesPlaceholders = false, the WidgetSpan should NOT
      // increment the index.
      final indicesWithoutPlaceholders = <int>[];
      span.visitChildrenEx((span, index) {
        indicesWithoutPlaceholders.add(index);
        return true;
      }, includesPlaceholders: false);
      // 'Hello' at 0, WidgetSpan at 5 (still visited), ' World' at 5
      // (not incremented by placeholder).
      expect(indicesWithoutPlaceholders, [0, 5, 5]);
    });
  });
}
