// Copyright (c) 2021 Ron Booth. All rights reserved.
// Use of this source code is governed by a license that can be found in the
// LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:selectable/selectable.dart';

void main() {
  group('SelectableController', () {
    late SelectableController controller;

    setUp(() {
      controller = SelectableController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('is a SelectableControllerBase', () {
      expect(controller, isA<SelectableControllerBase>());
    });

    test('isTextSelected is false initially', () {
      expect(controller.isTextSelected, isFalse);
    });

    test('getSelection returns non-null main selection', () {
      expect(controller.getSelection(), isNotNull);
    });

    test('getSelection returns null for non-existent key', () {
      expect(controller.getSelection(key: 99), isNull);
    });

    test('getContainedText returns empty string initially', () {
      expect(controller.getContainedText(), isEmpty);
    });

    test('deselectAll returns false when nothing is selected', () {
      expect(controller.deselectAll(), isFalse);
    });

    test('deselect returns false when nothing is selected', () {
      expect(controller.deselect(), isFalse);
    });

    test('deselect with key returns false when key does not exist', () {
      expect(controller.deselect(key: 99), isFalse);
    });

    test('hide returns false when no selection exists for key', () {
      expect(controller.hide(key: 99), isFalse);
    });

    test('unhide returns false when no selection exists for key', () {
      expect(controller.unhide(key: 99), isFalse);
    });

    test('setCustomPainter and getCustomPainter round-trip', () {
      final painter = _TestSelectionPainter();
      controller.setCustomPainter(painter);
      expect(controller.getCustomPainter(), same(painter));
    });

    test('setCustomPainter with key and getCustomPainter with key', () {
      final painter = _TestSelectionPainter();
      controller.setCustomPainter(painter, key: 5);
      expect(controller.getCustomPainter(key: 5), same(painter));
      expect(controller.getCustomPainter(), isNull);
    });

    test('setCustomPainter null removes painter', () {
      final painter = _TestSelectionPainter();
      controller.setCustomPainter(painter);
      expect(controller.getCustomPainter(), isNotNull);
      controller.setCustomPainter(null);
      expect(controller.getCustomPainter(), isNull);
    });

    test('setCustomPainter notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setCustomPainter(_TestSelectionPainter());
      expect(notified, isTrue);
    });

    test('removing custom painter notifies listeners', () {
      controller.setCustomPainter(_TestSelectionPainter());
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setCustomPainter(null);
      expect(notified, isTrue);
    });

    test('setCustomRectifier and getCustomRectifier round-trip', () {
      List<Rect> rectifier(List<Rect> rects) => rects;
      controller.setCustomRectifier(rectifier);
      expect(controller.getCustomRectifier(), same(rectifier));
    });

    test('setCustomRectifier with key and getCustomRectifier with key', () {
      List<Rect> rectifier(List<Rect> rects) => rects;
      controller.setCustomRectifier(rectifier, key: 3);
      expect(controller.getCustomRectifier(key: 3), same(rectifier));
      expect(controller.getCustomRectifier(), isNull);
    });

    test('setCustomRectifier null removes rectifier', () {
      List<Rect> rectifier(List<Rect> rects) => rects;
      controller.setCustomRectifier(rectifier);
      expect(controller.getCustomRectifier(), isNotNull);
      controller.setCustomRectifier(null);
      expect(controller.getCustomRectifier(), isNull);
    });

    test('setCustomRectifier notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setCustomRectifier((rects) => rects);
      expect(notified, isTrue);
    });

    test('selectWordsBetweenPoints with negative key returns false', () {
      expect(
        controller.selectWordsBetweenPoints(Offset.zero, Offset.zero, key: -1),
        isFalse,
      );
    });

    test('visitContainedSpans returns true when no paragraphs', () {
      expect(controller.visitContainedSpans((p, s, i) => true), isTrue);
    });
  });
}

class _TestSelectionPainter extends SelectionPainter {
  @override
  void paint(Canvas canvas, Size size, Selection selection) {}

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) => false;
}
