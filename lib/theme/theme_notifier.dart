// lib/services/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

class ThemeNotifier with ChangeNotifier {
  static ThemeMode? _themeMode;
  static bool? _useMaterialYou;
  static Color? _customAccentColor;

  ThemeNotifier();

  Future<void> init() async {
    await _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? savedThemeMode = preferences.getString('themeMode');
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == 'ThemeMode.$savedThemeMode',
        orElse: () => ThemeMode.system,
      );
    }
    _useMaterialYou = preferences.getBool('useMaterialYou');

    int? savedAccentColorValue = preferences.getInt('customAccentColor');
    if (savedAccentColorValue != null) {
      _customAccentColor = Color(savedAccentColorValue);
    }
  }

  ThemeMode currentTheme(BuildContext context) {
    if (_themeMode == null) {
      return ThemeMode.system;
    } else if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;
    }
    return _themeMode!;
  }

  ThemeMode getStoredThemeMode() {
    return _themeMode ?? ThemeMode.system;
  }

  bool get useMaterialYou => _useMaterialYou ?? false;

  Color? get customAccentColor => _customAccentColor;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemePreference(mode);
      setSystemNavigationBarIconBrightness(mode);
      notifyListeners();
    }
  }

  void setUseMaterialYou(bool value) {
    if (_useMaterialYou != value) {
      _useMaterialYou = value;
      _saveMaterialYouPreference(value);
      notifyListeners();
    }
  }

  void setCustomAccentColor(Color color) {
    if (_customAccentColor != color) {
      _customAccentColor = color;
      _saveCustomAccentColorPreference(color);
      notifyListeners();
    }
  }

  void _saveThemePreference(ThemeMode mode) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('themeMode', mode.name);
  }

  void _saveMaterialYouPreference(bool useMaterialYou) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('useMaterialYou', useMaterialYou);
  }

  void _saveCustomAccentColorPreference(Color color) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt('customAccentColor', color.value);
  }

  void setSystemNavigationBarIconBrightness(ThemeMode mode) {
    Brightness iconBrightness;
    if (mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            SchedulerBinding.instance.window.platformBrightness ==
                Brightness.dark)) {
      iconBrightness = Brightness.light;
    } else {
      iconBrightness = Brightness.dark;
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );
  }
}
