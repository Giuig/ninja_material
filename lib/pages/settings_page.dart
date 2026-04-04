import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ninja_material/utils/svg_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/shared_config.dart';
import '../l10n/app_localizations.dart';

class _SupportOption {
  final String label;
  final IconData icon;
  final String url;
  const _SupportOption(
      {required this.label, required this.icon, required this.url});
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _githubUrl = 'https://github.com/Giuig';

  static const _supportOptions = [
    _SupportOption(
      label: 'Ko-fi',
      icon: Icons.coffee_outlined,
      url: 'https://ko-fi.com/giuig',
    ),
  ];

  final List<Locale> _localeOptions = globalAllowedLocales;

  ThemeMode _selectedThemeMode = ThemeMode.system;
  bool _useMaterialYou = false;
  Color _selectedAccentColor = Colors.blue.shade500;

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'ja': '日本語',
  };

  @override
  void initState() {
    super.initState();
    _updateSettingsState();
    globalCurrentTheme.addListener(_updateSettingsState);
  }

  @override
  void dispose() {
    globalCurrentTheme.removeListener(_updateSettingsState);
    super.dispose();
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      clipBehavior: Clip.antiAlias,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final opt in _supportOptions)
              ListTile(
                leading: Icon(opt.icon),
                title: Text(opt.label),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl(opt.url);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _updateSettingsState() {
    setState(() {
      _selectedThemeMode = globalCurrentTheme.getStoredThemeMode();
      _useMaterialYou = globalCurrentTheme.useMaterialYou;
      final currentCustomColor = globalCurrentTheme.customAccentColor;
      if (currentCustomColor != null &&
          globalThemeColorOptions.containsValue(currentCustomColor)) {
        _selectedAccentColor = currentCustomColor;
      } else {
        _selectedAccentColor =
            globalThemeColorOptions['Default'] ?? Colors.blue.shade500;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedLocale = globalCurrentLocale.currentLocale(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: Material(
                color: Colors.transparent,
                child: ListView(
                children: [
                // ── Theme Mode ───────────────────────────────────────────────
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(l10n.themeMode),
                  trailing: DropdownMenu<ThemeMode>(
                    key: ValueKey(selectedLocale),
                    width: 190,
                    initialSelection: _selectedThemeMode,
                    requestFocusOnTap: false,
                    onSelected: (ThemeMode? mode) {
                      if (mode != null) {
                        globalCurrentTheme.setThemeMode(mode);
                      }
                    },
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: ThemeMode.system,
                        label: l10n.systemTheme,
                        leadingIcon: const Icon(
                            Icons.brightness_auto_outlined, size: 18),
                      ),
                      DropdownMenuEntry(
                        value: ThemeMode.light,
                        label: l10n.lightTheme,
                        leadingIcon: const Icon(
                            Icons.light_mode_outlined, size: 18),
                      ),
                      DropdownMenuEntry(
                        value: ThemeMode.dark,
                        label: l10n.darkTheme,
                        leadingIcon: const Icon(
                            Icons.dark_mode_outlined, size: 18),
                      ),
                    ],
                  ),
                ),

                // ── Material You ─────────────────────────────────────────────
                if (globalCurrentTheme.supportsDynamicColor)
                  SwitchListTile(
                    title: Text(l10n.useMaterialYou),
                    value: _useMaterialYou,
                    onChanged: (value) {
                      setState(() {
                        _useMaterialYou = value;
                        globalCurrentTheme.setUseMaterialYou(value);
                      });
                    },
                  ),

                // ── Theme Accent ──────────────────────────────────────────────
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(l10n.themeAccent),
                  trailing: DropdownMenu<Color>(
                    key: ValueKey(selectedLocale),
                    width: 190,
                    enabled: !_useMaterialYou,
                    initialSelection: _selectedAccentColor,
                    requestFocusOnTap: false,
                    onSelected: (Color? color) {
                      if (color != null) {
                        globalCurrentTheme.setCustomAccentColor(color);
                      }
                    },
                    dropdownMenuEntries: globalThemeColorOptions.entries
                        .map((entry) => DropdownMenuEntry<Color>(
                              value: entry.value,
                              label: entry.key == 'Default'
                                  ? l10n.defaultColor
                                  : entry.key,
                              leadingIcon: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: colorScheme.outline, width: 1),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),

                // ── Language ──────────────────────────────────────────────────
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(l10n.language),
                  trailing: DropdownMenu<Locale>(
                    key: ValueKey(selectedLocale),
                    width: 160,
                    initialSelection: selectedLocale,
                    requestFocusOnTap: false,
                    onSelected: (Locale? locale) {
                      if (locale != null) {
                        globalCurrentLocale.switchLocale(locale);
                      }
                    },
                    dropdownMenuEntries: _localeOptions
                        .map((locale) => DropdownMenuEntry<Locale>(
                              value: locale,
                              label: _languageNames[locale.languageCode] ??
                                  locale.languageCode.toUpperCase(),
                            ))
                        .toList(),
                  ),
                ),

                // ── Support ───────────────────────────────────────────────────
                const Divider(height: 1),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(Icons.favorite_outline),
                  title: Text(l10n.support),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSupportSheet(context),
                ),
              ],
              ),
            ),
          ),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "© $globalCurrentYear ${globalAppName![0].toUpperCase()}${globalAppName!.substring(1).toLowerCase()}",
                      style: TextStyle(
                          fontSize: 12.0, color: colorScheme.onSurface),
                    ),
                    Text(", Made with ",
                        style: TextStyle(
                            fontSize: 12.0, color: colorScheme.onSurface)),
                    SvgPicture.string(SvgUtil.flutterSvgString,
                        width: 17, height: 17),
                  ],
                ),
                Text(
                  "Version: $globalVersion",
                  style:
                      TextStyle(fontSize: 12.0, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'GitHub',
                      child: IconButton(
                        onPressed: () => _launchUrl(_githubUrl),
                        icon: SvgPicture.string(
                          SvgUtil.githubSvgString,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                              colorScheme.onSurfaceVariant, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
