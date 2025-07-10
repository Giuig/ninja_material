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
  Future<void> _showClearDataDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.areYouSure),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.resetCountDescription),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          globalAppName?.toLowerCase() == 'decisioninja'
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Wrap(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _showClearDataDialog,
                        child: Text(
                          AppLocalizations.of(context)!.resetCount,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink(),
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
                  "Version: $globalVersion",
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
