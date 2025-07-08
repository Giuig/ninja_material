import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  static bool? isDark;

  Future<void> _loadSavedTheme() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    isDark = preferences.getBool('isDark');

    setSystemNavigationBarIconBrightness();

    notifyListeners();
  }

  ThemeMode currentTheme(BuildContext context) {
    Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);

    isDark ??= platformBrightness == Brightness.dark;

    setSystemNavigationBarIconBrightness();

    return isDark! ? ThemeMode.dark : ThemeMode.light;
  }

  void switchTheme() {
    isDark = !isDark!;
    _saveThemePreference(isDark!);

    setSystemNavigationBarIconBrightness();

    notifyListeners();
  }

  void _saveThemePreference(bool isDark) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('isDark', isDark);
  }

  ThemeNotifier() {
    _loadSavedTheme();
  }

  void setSystemNavigationBarIconBrightness() {
    final isDark = ThemeNotifier.isDark;
    if (isDark == null) return; // or set a default
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
