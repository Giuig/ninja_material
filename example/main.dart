// main.dart

import 'package:flutter/material.dart';
import 'package:ninja_material/bootstrap.dart'; // Path to your bootstrap file
import 'package:ninja_material/l10n/app_localizations.dart'; // Your app's localization delegate

import 'config.dart'; // Assuming config.dart holds appFirstPageConfig

void main() {
  // Call the bootstrapping function with necessary parameters
  runNinjaApp(
    defaultSeedColor: Colors.blue, // Your desired default app color
    specificLocalizationDelegate: AppLocalizations.delegate,
    appFirstPageConfig:
        appFirstPageConfig, // Assuming appFirstPageConfig comes from config.dart
  );
}
