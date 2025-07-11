// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, prefer_const_literals_to_create_immutables, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ninja_material/utils/svg_util.dart';

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

  bool _changeTheme = false;

  @override
  Widget build(BuildContext context) {
    Locale selectedLocale = globalCurrentLocale.currentLocale(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.changeTheme),
                  value: _changeTheme,
                  onChanged: (value) {
                    setState(() {
                      _changeTheme = value;
                      globalCurrentTheme.switchTheme();
                    });
                  },
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
