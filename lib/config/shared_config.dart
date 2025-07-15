// lib/config/shared_config.dart
import 'package:flutter/material.dart';
import 'package:ninja_material/config/locale_notifier.dart';
import 'package:ninja_material/theme/theme_notifier.dart';

final globalCurrentTheme = ThemeNotifier();
final globalCurrentLocale = LocaleNotifier();

int globalCurrentYear = DateTime.now().year;
String? globalAppName;
String? globalVersion;
String? globalBuildNumber;

final Map<String, Color> globalThemeColorOptions = {
  'Ditto': Colors.purple.shade500,
  'Charmander': Colors.red.shade500,
  'Squirtle': Colors.blue.shade500,
  'Bulbasaur': Colors.green.shade500,
  'Pikachu': Colors.yellow.shade500,
};
