// ignore_for_file: prefer_const_constructors

import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ninja_material/config/shared_config.dart';
import 'package:ninja_material/l10n/l10n.dart';
import 'package:ninja_material/pages/first_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ninja_material/l10n/app_localizations.dart';

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  //await initializeGlobals();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;

  inspect(packageName);

  globalAppName = appName;
  globalVersion = version;
  globalBuildNumber = buildNumber;

  final style = SystemUiOverlayStyle(
    systemNavigationBarColor: const Color.fromARGB(0, 255, 153, 0),
    systemNavigationBarContrastEnforced: false,
  );

  SystemChrome.setSystemUIOverlayStyle(style);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    globalCurrentTheme.addListener(() {
      setState(() {});
    });
    globalCurrentLocale.addListener(() {
      setState(() {});
    });
  }

  static final _defaultLightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue, brightness: Brightness.light);

  static final _defaultDarkColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        final effectiveLightColorScheme =
            lightColorScheme ?? _defaultLightColorScheme;
        final effectiveDarkColorScheme =
            darkColorScheme ?? _defaultDarkColorScheme;

        final enhancedLightColorScheme = ColorScheme.fromSeed(
          seedColor: effectiveLightColorScheme.primary,
          brightness: Brightness.light,
        );

        final enhancedDarkColorScheme = ColorScheme.fromSeed(
          seedColor: effectiveDarkColorScheme.primary,
          brightness: Brightness.dark,
        );

        return MaterialApp(
            theme: ThemeData(
              colorScheme: enhancedLightColorScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: enhancedDarkColorScheme,
              useMaterial3: true,
            ),
            themeMode: globalCurrentTheme.currentTheme(context),
            supportedLocales: L10n.all,
            locale: globalCurrentLocale.currentLocale(context),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FirstPage.withConfig(config: appFirstPageConfig));
      },
    );
  }
}
