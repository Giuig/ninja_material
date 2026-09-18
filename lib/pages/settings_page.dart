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
  /// App-specific settings rows, appended after the shared ones and before the
  /// Support block.
  ///
  /// The shared page deliberately owns only what every ninja app has — theme,
  /// colour, language. Anything specific to one app (tvninja's "always start in
  /// audio-only", say) comes through here, so apps do not have to fork the page
  /// or invent a second settings screen.
  final List<Widget>? extraSettings;

  const SettingsPage({super.key, this.extraSettings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Shared width for all three settings dropdowns.
  ///
  /// Was 190 on two of them and unset on the third, which produced both
  /// visible defects: Italian's "Tema di sistema" truncated to "Tema di
  /// sistem", and the language dropdown sitting at a different width from the
  /// other two. One constant keeps them aligned and stops them drifting apart
  /// again. 220 fits the longest current option across the shipped locales at
  /// the default text scale — a much longer translation, or a large system
  /// font, can still clip, which wants a non-fixed width rather than a bigger
  /// number.
  static const double _dropdownWidth = 220;

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

    // No Scaffold of its own. This page renders inside FirstPage's Scaffold
    // body, which already supplies the background colour and a Material
    // ancestor, so the nested one just painted an identical background over
    // the first — and gave this subtree a second round of inset handling,
    // which is wrong now that FirstPage insets the rail's content itself.
    return Column(
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
                    width: _dropdownWidth,
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
                    width: _dropdownWidth,
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
                    width: _dropdownWidth,
                    key: ValueKey(selectedLocale),
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

                // ── App-specific ─────────────────────────────────────────────
                // Placed after the shared settings and before Support so an
                // app's own rows read as settings, not as an afterthought
                // below the footer links.
                if (widget.extraSettings != null &&
                    widget.extraSettings!.isNotEmpty) ...[
                  const Divider(height: 1),
                  ...widget.extraSettings!,
                ],

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
          // One wrapping row rather than a four-item stack. The old layout was
          // ~133 logical px: 30 of outer padding, 22 of stacked SizedBox
          // spacers, ~33 of text, and a 48px row holding one 20px icon.
          //
          // The 48 stays — that is Material's minimum tap target, and shrinking
          // it would trade height for an accessibility regression. Everything
          // else collapses into the row the icon already needs, so the footer
          // costs roughly what that button costs and nothing more.
          //
          // Wrap, not Row: a long app name or a large system font falls onto a
          // second line instead of overflowing.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  "© $globalCurrentYear $globalFormattedAppName",
                  style:
                      TextStyle(fontSize: 12.0, color: colorScheme.onSurface),
                ),
                Text(
                  "v$globalVersion",
                  style:
                      TextStyle(fontSize: 12.0, color: colorScheme.onSurface),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Made with ",
                        style: TextStyle(
                            fontSize: 12.0, color: colorScheme.onSurface)),
                    SvgPicture.string(SvgUtil.flutterSvgString,
                        width: 15, height: 15),
                  ],
                ),
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
          ),
      ],
    );
  }
}
