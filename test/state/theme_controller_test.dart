import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/state/theme_controller.dart';

void main() {
  test('toggle switches between light and dark, defaults from system', () {
    final controller = ThemeController();
    expect(controller.mode, ThemeMode.system);

    controller.toggle();
    expect(controller.mode, ThemeMode.dark);

    controller.toggle();
    expect(controller.mode, ThemeMode.light);
  });

  test('toggle notifies listeners', () {
    final controller = ThemeController();
    var notified = false;
    controller.addListener(() => notified = true);

    controller.toggle();

    expect(notified, isTrue);
  });
}
