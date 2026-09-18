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

/// [globalAppName] with a capital first letter and the rest lower-cased.
///
/// The same expression was inlined in two places (the AppBar title and the
/// settings footer), so a change to how the name is presented had to be made
/// twice or the two would disagree. Throws the same way the old inline code
/// did if `globalAppName` is unset, which only happens before `runNinjaApp`
/// has read the package info.
String get globalFormattedAppName =>
    globalAppName![0].toUpperCase() + globalAppName!.substring(1).toLowerCase();

final Map<String, Color> globalThemeColorOptions = {
  'Bulbasaur': Colors.teal.shade500,
  'Charmander': Colors.deepOrange.shade400,
  'Squirtle': Colors.lightBlue.shade600,
  'Pikachu': Colors.amber.shade500,
  'Ditto': Colors.purple.shade300,
  'Eevee': Colors.brown.shade400,
};
