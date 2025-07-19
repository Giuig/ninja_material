import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'config/shared_config.dart';
import 'l10n/l10n.dart';
import 'pages/first_page.dart';

Future<void> runNinjaApp({
  required Color defaultSeedColor,
  required LocalizationsDelegate<dynamic> specificLocalizationDelegate,
  required FirstPageConfig appFirstPageConfig,
  List<Future<void> Function()> additionalFunctions = const [],
  List<SingleChildWidget> additionalProviders = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await globalCurrentTheme.init();
  await globalCurrentLocale.init();

  bool supportsDynamicColor = false;
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    supportsDynamicColor = corePalette != null;
  } catch (_) {
    supportsDynamicColor = false;
  }

  globalCurrentTheme.setSupportsDynamicColor(supportsDynamicColor);

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

  final Map<String, Color> orderedThemeColorOptions = {};
  orderedThemeColorOptions['Default'] = defaultSeedColor;
  orderedThemeColorOptions.addAll(globalThemeColorOptions);
  globalThemeColorOptions
    ..clear()
    ..addAll(orderedThemeColorOptions);

  runApp(
    MultiProvider(
      providers: [
        ...additionalProviders,
      ],
      child: _NinjaApp(
        defaultSeedColor: defaultSeedColor,
        specificLocalizationDelegate: specificLocalizationDelegate,
        appFirstPageConfig: appFirstPageConfig,
      ),
    ),
  );
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
    globalCurrentTheme.addListener(_onThemeChanged);
    globalCurrentLocale.addListener(_onLocaleChanged);
  }

  void _onThemeChanged() => setState(() {});
  void _onLocaleChanged() => setState(() {});

  @override
  void dispose() {
    globalCurrentTheme.removeListener(_onThemeChanged);
    globalCurrentLocale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        ColorScheme light;
        ColorScheme dark;

        Color effectiveSeedColor = widget.defaultSeedColor;

        if (!globalCurrentTheme.useMaterialYou &&
            globalCurrentTheme.customAccentColor != null) {
          effectiveSeedColor = globalCurrentTheme.customAccentColor!;
        }

        if (globalCurrentTheme.supportsDynamicColor &&
            globalCurrentTheme.useMaterialYou &&
            lightColorScheme != null &&
            darkColorScheme != null) {
          light = lightColorScheme;
          dark = darkColorScheme;
        } else {
          light = ColorScheme.fromSeed(
            seedColor: effectiveSeedColor,
            brightness: Brightness.light,
          );
          dark = ColorScheme.fromSeed(
            seedColor: effectiveSeedColor,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: globalCurrentTheme.currentTheme(context),
          theme: ThemeData(
            colorScheme: light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: dark,
            useMaterial3: true,
          ),
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
