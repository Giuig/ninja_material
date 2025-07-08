library;

import '../theme/theme_notifier.dart';
import 'locale_notifier.dart';

ThemeNotifier globalCurrentTheme = ThemeNotifier();
LocaleNotifier globalCurrentLocale = LocaleNotifier();

String? globalAppName;
String? globalVersion;

String globalCurrentYear = getCurrentYear();

String getCurrentYear() {
  return DateTime.now().year.toString();
}
