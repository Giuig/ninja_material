import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

LocalizationsDelegate<dynamic>? _globalAppLocalizationDelegate;

/// Locales supported by both ninja_material and the current app's delegate.
List<Locale> get globalAllowedLocales {
  final delegate = _globalAppLocalizationDelegate;
  if (delegate == null) return L10n.all;
  return L10n.all.where((locale) => delegate.isSupported(locale)).toList();
}

void setGlobalAppLocalizationDelegate(LocalizationsDelegate<dynamic> delegate) {
  _globalAppLocalizationDelegate = delegate;
}
