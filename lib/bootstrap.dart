import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/shared_config.dart';
import 'l10n/l10n.dart';
import 'pages/first_page.dart';

Future<void> runNinjaApp({
  required Color defaultSeedColor,
  required LocalizationsDelegate<dynamic> specificLocalizationDelegate,
  required FirstPageConfig appFirstPageConfig,
  List<Future<void> Function()> additionalFunctions = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await globalCurrentTheme.init();
  await globalCurrentLocale.init();

  bool supportsDynamicColor = false;
  try {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    supportsDynamicColor = corePalette != null;
  } catch (e) {
    debugPrint('DynamicColorPlugin.getCorePalette() failed: $e');
    supportsDynamicColor = false;
  }
  globalCurrentTheme.setSupportsDynamicColor(supportsDynamicColor);

  for (final function in additionalFunctions) {
    await function();
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

  globalThemeColorOptions.clear();
  globalThemeColorOptions.addAll(orderedThemeColorOptions);

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
  void dispose() {
    globalCurrentTheme.removeListener(() => setState(() {}));
    globalCurrentLocale.removeListener(() => setState(() {}));
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
