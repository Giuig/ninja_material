// lib/config/shared_config.dart
import 'package:flutter/material.dart';
import 'package:ninja_material/config/locale_notifier.dart';
import 'package:ninja_material/theme/theme_notifier.dart';

export 'locale_config.dart';

final globalCurrentTheme = ThemeNotifier();
final globalCurrentLocale = LocaleNotifier();

int globalCurrentYear = DateTime.now().year;
String? globalAppName;
String? globalVersion;
String? globalBuildNumber;

final Map<String, Color> globalThemeColorOptions = {
  'Bulbasaur': Colors.teal.shade500,
  'Charmander': Colors.deepOrange.shade400,
  'Squirtle': Colors.lightBlue.shade600,
  'Pikachu': Colors.amber.shade500,
  'Ditto': Colors.purple.shade300,
  'Eevee': Colors.brown.shade400,
};
