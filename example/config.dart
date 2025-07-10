import 'package:flutter/material.dart';
import 'package:ninja_material/Pages/first_page.dart';
import 'package:ninja_material/l10n/app_localizations.dart';

import 'home_page.dart';

final FirstPageConfig appFirstPageConfig = FirstPageConfig(
  destinationsBuilder: appDestinationsBuilder,
  pages: appPages,
);

final appPages = [HomePage()];

// ignore: prefer_function_declarations_over_variables
final appDestinationsBuilder = (context) => [
      NavigationDestination(
        selectedIcon: Icon(Icons.home),
        icon: Icon(Icons.home_outlined),
        label: AppLocalizations.of(context)!.home,
      ),
    ];
