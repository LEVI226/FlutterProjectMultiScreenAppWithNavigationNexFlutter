import 'package:flutter/widgets.dart';

const _supportedLocales = [Locale('en'), Locale('fr')];

class LocaleController extends ChangeNotifier {
  LocaleController({required Locale deviceLocale})
    : _locale = _supportedLocales.contains(Locale(deviceLocale.languageCode))
          ? Locale(deviceLocale.languageCode)
          : const Locale('en');

  Locale _locale;

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}

class LocaleControllerScope extends InheritedNotifier<LocaleController> {
  const LocaleControllerScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>();
    assert(scope != null, 'No LocaleControllerScope found in context');
    return scope!.notifier!;
  }
}
