import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:savorly/state/locale_controller.dart';

void main() {
  test('defaults to the given device locale when supported', () {
    final controller = LocaleController(deviceLocale: const Locale('fr'));
    expect(controller.locale, const Locale('fr'));
  });

  test('falls back to English when the device locale is not supported', () {
    final controller = LocaleController(deviceLocale: const Locale('de'));
    expect(controller.locale, const Locale('en'));
  });

  test('setLocale updates the locale and notifies listeners', () {
    final controller = LocaleController(deviceLocale: const Locale('en'));
    var notified = false;
    controller.addListener(() => notified = true);

    controller.setLocale(const Locale('fr'));

    expect(controller.locale, const Locale('fr'));
    expect(notified, isTrue);
  });
}
