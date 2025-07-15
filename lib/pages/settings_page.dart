// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, prefer_const_literals_to_create_immutables, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ninja_material/utils/svg_util.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dynamic_color/dynamic_color.dart';

import '../config/shared_config.dart';
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

  // Map for theme color options - using specific shades for uniqueness
  late final Map<String, Color> _themeColorOptions;

  ThemeMode _selectedThemeMode = ThemeMode.system;
  bool _useMaterialYou = false;
  bool _supportsDynamicColor = false;
  Color _selectedAccentColor =
      Colors.blue.shade500; // Default to a specific shade

  @override
  void initState() {
    super.initState();

    // Initialize theme color options with unique Color instances (using .shade500)
    _themeColorOptions = {
      'Default': Colors.indigo.shade500, // A distinct default color
      'Ditto': Colors.purple.shade500,
      'Charmander': Colors.red.shade500,
      'Squirtle': Colors.blue.shade500,
      'Bulbasaur': Colors.green.shade500,
      'Pikachu': Colors.yellow.shade500,
    };

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateSettingsState(); // Initial state update after build context is ready
    });

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

      // Update selected accent color from global state.
      Color? currentCustomColor = globalCurrentTheme.customAccentColor;

      // If a custom color is saved AND it exists in our predefined options, use it.
      // Otherwise, fall back to the 'Default' color defined in _themeColorOptions.
      if (currentCustomColor != null &&
          _themeColorOptions.containsValue(currentCustomColor)) {
        _selectedAccentColor = currentCustomColor;
      } else {
        _selectedAccentColor = _themeColorOptions['Default']!;
      }
    });
  }

  Future<void> _checkDynamicColorSupport() async {
    final dynamic corePalette = await DynamicColorPlugin.getCorePalette();
    setState(() {
      _supportsDynamicColor = corePalette != null;
    });
  }

  // Helper to get localized theme mode name
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

  // Helper to get the key (name) for a given color from the map
  String _getAccentColorName(Color color) {
    return _themeColorOptions.entries
        .firstWhere((entry) => entry.value == color,
            orElse: () => MapEntry('Default', Colors.indigo.shade500))
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
                // Theme Mode Dropdown
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

                if (_supportsDynamicColor)
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

                // Theme Accent Color Dropdown (without colored circles)
                ListTile(
                  title: Text(AppLocalizations.of(context)!.themeAccent),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<Color>(
                      value: _selectedAccentColor,
                      // Disable if Material You is enabled
                      onChanged: _useMaterialYou
                          ? null
                          : (Color? newValue) {
                              if (newValue != null) {
                                globalCurrentTheme
                                    .setCustomAccentColor(newValue);
                              }
                            },
                      items: _themeColorOptions.entries
                          .map<DropdownMenuItem<Color>>(
                              (MapEntry<String, Color> entry) {
                        return DropdownMenuItem<Color>(
                          value: entry.value,
                          // Removed Row with Container for colored circle
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
            padding: EdgeInsets.all(15.0),
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
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "© $globalCurrentYear ${globalAppName![0].toUpperCase()}${globalAppName!.substring(1).toLowerCase()}",
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
                  "Version: $globalVersion ($globalBuildNumber)",
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
