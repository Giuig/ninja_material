import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ninja_material/utils/svg_util.dart';
import 'package:url_launcher/url_launcher.dart';
// dynamic_color import is no longer needed here as the check is externalized
// import 'package:dynamic_color/dynamic_color.dart'; // REMOVED

import '../config/shared_config.dart'; // This now provides supportsDynamicColor
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Locale> _localeOptions = L10n.all;
  final List<ThemeMode> _themeModeOptions = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  ThemeMode _selectedThemeMode = ThemeMode.system;
  bool _useMaterialYou = false;
  // bool _supportsDynamicColor = false; // REMOVED: No longer a state variable here
  Color _selectedAccentColor = Colors.blue.shade500;

  @override
  void initState() {
    super.initState();

    _updateSettingsState();
    // _checkDynamicColorSupport(); // REMOVED: Check is now done in bootstrap.dart

    globalCurrentTheme.addListener(_updateSettingsState);
  }

  @override
  void dispose() {
    globalCurrentTheme.removeListener(_updateSettingsState);
    super.dispose();
  }

  void _updateSettingsState() {
    setState(() {
      _selectedThemeMode = globalCurrentTheme.getStoredThemeMode();
      _useMaterialYou = globalCurrentTheme.useMaterialYou;

      Color? currentCustomColor = globalCurrentTheme.customAccentColor;

      if (currentCustomColor != null &&
          globalThemeColorOptions.containsValue(currentCustomColor)) {
        _selectedAccentColor = currentCustomColor;
      } else {
        // Ensure 'Default' key exists or handle its absence
        _selectedAccentColor =
            globalThemeColorOptions['Default'] ?? Colors.blue.shade500;
      }
    });
  }

  // Future<void> _checkDynamicColorSupport() async { // REMOVED: Check is now done in bootstrap.dart
  //   final dynamic corePalette = await DynamicColorPlugin.getCorePalette();
  //   setState(() {
  //     _supportsDynamicColor = corePalette != null;
  //   });
  // }

  String _getThemeModeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppLocalizations.of(context)!.systemTheme;
      case ThemeMode.light:
        return AppLocalizations.of(context)!.lightTheme;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.darkTheme;
    }
  }

  String _getAccentColorName(Color color) {
    return globalThemeColorOptions.entries
        .firstWhere((entry) => entry.value == color,
            orElse: () =>
                MapEntry('Default', globalThemeColorOptions['Default']!))
        .key;
  }

  @override
  Widget build(BuildContext context) {
    Locale selectedLocale = globalCurrentLocale.currentLocale(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text(AppLocalizations.of(context)!.themeMode),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: _selectedThemeMode,
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          globalCurrentTheme.setThemeMode(newValue);
                        }
                      },
                      items: _themeModeOptions
                          .map<DropdownMenuItem<ThemeMode>>((ThemeMode value) {
                        return DropdownMenuItem<ThemeMode>(
                          value: value,
                          child: Text(_getThemeModeName(context, value)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Access dynamic color support directly from globalCurrentTheme
                if (globalCurrentTheme
                    .supportsDynamicColor) // Use the value from ThemeNotifier
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.useMaterialYou),
                    value: _useMaterialYou,
                    onChanged: (value) {
                      setState(() {
                        _useMaterialYou = value;
                        globalCurrentTheme.setUseMaterialYou(value);
                      });
                    },
                  ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.themeAccent),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<Color>(
                      value: _selectedAccentColor,
                      onChanged: _useMaterialYou
                          ? null
                          : (Color? newValue) {
                              if (newValue != null) {
                                globalCurrentTheme
                                    .setCustomAccentColor(newValue);
                              }
                            },
                      items: globalThemeColorOptions.entries
                          .map<DropdownMenuItem<Color>>(
                              (MapEntry<String, Color> entry) {
                        return DropdownMenuItem<Color>(
                          value: entry.value,
                          child: Text(entry.key),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.language),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: selectedLocale,
                      onChanged: (Locale? newValue) {
                        setState(() {
                          selectedLocale = newValue!;
                          globalCurrentLocale.switchLocale(newValue);
                        });
                      },
                      items: _localeOptions
                          .map<DropdownMenuItem<Locale>>((Locale value) {
                        return DropdownMenuItem<Locale>(
                          value: value,
                          child: Text(value.languageCode.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse('https://ko-fi.com/ninjapp');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Image.network(
                    'https://storage.ko-fi.com/cdn/kofi5.png',
                    height: 45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "© ${globalCurrentYear} ${globalAppName![0].toUpperCase()}${globalAppName!.substring(1).toLowerCase()}",
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      ", Made with ",
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SvgPicture.string(
                      SvgUtil.flutterSvgString,
                      width: 17,
                      height: 17,
                    ),
                  ],
                ),
                Text(
                  "Version: ${globalVersion} (${globalBuildNumber})",
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
