import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

class LocaleNotifier extends ChangeNotifier {
  static Locale? _currentLocale;
  final defaultLocale = const Locale('en');

  Future<void> _loadSavedLocale() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String savedLocale = preferences.getString('locale') ??
        PlatformDispatcher.instance.locale.languageCode;
    _currentLocale = Locale(savedLocale);
    notifyListeners();
  }

  Locale currentLocale(BuildContext context) {
    if (L10n.all.contains(_currentLocale)) {
      return _currentLocale!;
    } else {
      return defaultLocale;
    }
  }

  void switchLocale(Locale newLocale) {
    _currentLocale = newLocale;
    _saveLocalePreference(newLocale.languageCode);
    notifyListeners();
  }

  void _saveLocalePreference(String locale) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('locale', locale);
  }

  LocaleNotifier() {
    _loadSavedLocale();
  }
}
