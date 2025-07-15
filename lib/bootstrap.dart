// lib/bootstrap.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/shared_config.dart';
import 'l10n/l10n.dart';
import 'pages/first_page.dart';

Future<void> runNinjaApp({
  required Color defaultSeedColor,
  required LocalizationsDelegate<dynamic> specificLocalizationDelegate,
  // Removed packageName as it's not used in this function's parameters directly.
  // It's fetched internally via PackageInfo.fromPlatform().
  required FirstPageConfig appFirstPageConfig,
  List<Future<void> Function()> additionalFunctions = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  for (final function in additionalFunctions) {
    await function();
  }

  if (!kIsWeb) {
    MobileAds.instance.initialize();
  }

  final info = await PackageInfo.fromPlatform();
  globalAppName = info.appName;
  globalVersion = info.version;
  globalBuildNumber = info.buildNumber;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color.fromARGB(0, 255, 153, 0),
      systemNavigationBarContrastEnforced: false,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(_NinjaApp(
    defaultSeedColor: defaultSeedColor,
    specificLocalizationDelegate: specificLocalizationDelegate,
    appFirstPageConfig: appFirstPageConfig,
  ));
}

class _NinjaApp extends StatefulWidget {
  final Color defaultSeedColor;
  final LocalizationsDelegate<dynamic> specificLocalizationDelegate;
  final FirstPageConfig appFirstPageConfig;

  const _NinjaApp({
    super.key,
    required this.defaultSeedColor,
    required this.specificLocalizationDelegate,
    required this.appFirstPageConfig,
  });

  @override
  State<_NinjaApp> createState() => _NinjaAppState();
}

class _NinjaAppState extends State<_NinjaApp> {
  @override
  void initState() {
    super.initState();
    globalCurrentTheme.addListener(() => setState(() {}));
    globalCurrentLocale.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        ColorScheme light;
        ColorScheme dark;

        // **This is the critical part.**
        // Determine the seed color based on:
        // 1. Material You preference.
        // 2. User's custom selected accent color.
        // 3. App's default seed color (if no custom accent or Material You).
        Color effectiveSeedColor =
            widget.defaultSeedColor; // Start with the app's initial default

        // If Material You is NOT enabled, and a custom accent color IS set, use it.
        // This ensures your selection from SettingsPage takes precedence.
        if (!globalCurrentTheme.useMaterialYou &&
            globalCurrentTheme.customAccentColor != null) {
          effectiveSeedColor = globalCurrentTheme.customAccentColor!;
        }

        // Apply Material You provided colors if enabled AND available
        if (globalCurrentTheme.useMaterialYou &&
            lightColorScheme != null &&
            darkColorScheme != null) {
          light = lightColorScheme; // Use dynamic colors directly
          dark = darkColorScheme; // Use dynamic colors directly
        } else {
          // Otherwise, generate ColorSchemes using our calculated effectiveSeedColor
          // This ensures customAccentColor is used when Material You is off.
          light = ColorScheme.fromSeed(
            seedColor: effectiveSeedColor, // Use the effective seed color
            brightness: Brightness.light,
          );
          dark = ColorScheme.fromSeed(
            seedColor: effectiveSeedColor, // Use the effective seed color
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          theme: ThemeData(
            colorScheme: light,
            useMaterial3:
                true, // Re-added Material 3 setting, highly recommended
          ),
          darkTheme: ThemeData(
            colorScheme: dark,
            useMaterial3: true, // Re-added Material 3 setting
          ),
          themeMode: globalCurrentTheme.currentTheme(context),
          supportedLocales: L10n.all,
          locale: globalCurrentLocale.currentLocale(context),
          localizationsDelegates: [
            widget.specificLocalizationDelegate,
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FirstPage.withConfig(config: widget.appFirstPageConfig),
        );
      },
    );
  }
}
