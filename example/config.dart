import 'package:flutter/material.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'package:ninja_material/pages/first_page.dart';

import 'home_page.dart';

final FirstPageConfig appFirstPageConfig = FirstPageConfig(
  destinationsBuilder: appDestinationsBuilder,
  pages: appPages,

  // Opt in to a NavigationRail on viewports at least 600 logical px wide.
  // Off by default, so an app that does not set this keeps the bottom
  // NavigationBar exactly as before. Resize the window to watch it switch.
  responsiveNavigation: true,

  // App-specific settings rows, appended to the shared settings page after
  // theme/colour/language and before the Support block. Without this hook an
  // app cannot add a preference at all.
  extraSettings: [
    const _ExampleSwitchSetting(),
  ],
);

/// Stands in for a real app preference — tvninja's "always start in
/// audio-only", say. Kept stateful so the example shows a row that actually
/// does something rather than a dead tile.
class _ExampleSwitchSetting extends StatefulWidget {
  const _ExampleSwitchSetting();
  @override
  State<_ExampleSwitchSetting> createState() => _ExampleSwitchSettingState();
}

class _ExampleSwitchSettingState extends State<_ExampleSwitchSetting> {
  bool _value = false;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: const Text('App-specific setting'),
        subtitle: const Text('Supplied by the app via extraSettings'),
        value: _value,
        onChanged: (v) => setState(() => _value = v),
      );
}

final appPages = [HomePage()];

// ignore: prefer_function_declarations_over_variables
final appDestinationsBuilder = (context) => [
      NavigationDestination(
        selectedIcon: Icon(Icons.home),
        icon: Icon(Icons.home_outlined),
        label: AppLocalizations.of(context)!.home,
      ),
    ];
