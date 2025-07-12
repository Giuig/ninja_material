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
  required String packageName,
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
    final defaultLight = ColorScheme.fromSeed(
      seedColor: widget.defaultSeedColor,
      brightness: Brightness.light,
    );
    final defaultDark = ColorScheme.fromSeed(
      seedColor: widget.defaultSeedColor,
      brightness: Brightness.dark,
    );

    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        final light = ColorScheme.fromSeed(
          seedColor: lightColorScheme?.primary ?? defaultLight.primary,
          brightness: Brightness.light,
        );

        final dark = ColorScheme.fromSeed(
          seedColor: darkColorScheme?.primary ?? defaultDark.primary,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          theme: ThemeData(colorScheme: light, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: dark, useMaterial3: true),
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
