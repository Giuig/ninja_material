import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

class LocaleNotifier extends ChangeNotifier {
  static Locale? _currentLocale;
  final defaultLocale = const Locale('en');

  // Remove the _loadSavedLocale() call from the constructor
  LocaleNotifier();

  // Add an async init method to load the locale
  Future<void> init() async {
    await _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String savedLocale = preferences.getString('locale') ??
        PlatformDispatcher.instance.locale.languageCode;
    _currentLocale = Locale(savedLocale);
    // Do NOT call notifyListeners() here, as init() will complete and then the app will build
    // with the correct initial locale. Subsequent changes will use switchLocale.
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
    notifyListeners(); // This will trigger UI rebuilds for locale changes
  }

  void _saveLocalePreference(String locale) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('locale', locale);
  }
}
