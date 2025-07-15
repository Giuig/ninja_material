// main.dart

import 'package:flutter/material.dart';
import 'package:ninja_material/bootstrap.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'config.dart';

void main() {
  runNinjaApp(
    defaultSeedColor: Colors.pink,
    specificLocalizationDelegate: AppLocalizations.delegate,
    appFirstPageConfig: appFirstPageConfig,
  );
}
