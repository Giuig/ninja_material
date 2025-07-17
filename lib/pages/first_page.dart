// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/global_notifier.dart';
import '../config/shared_config.dart';
import '../l10n/app_localizations.dart';
import 'settings_page.dart';

class FirstPageConfig {
  final List<NavigationDestination> Function(BuildContext) destinationsBuilder;
  final List<Widget> pages;
  final Widget? bottomBar;

  const FirstPageConfig({
    required this.destinationsBuilder,
    required this.pages,
    this.bottomBar,
  });
}

class FirstPage extends StatefulWidget {
  final FirstPageConfig? config;

  const FirstPage({super.key}) : config = null;

  const FirstPage.withConfig({
    super.key,
    required FirstPageConfig this.config,
  });

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _currentPageIndex = 0;
  late List<Widget> _pages;
  late List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();

    _pages = [
      ...widget.config?.pages ?? [],
      SettingsPage(),
    ];

    debugPrint("🔍 Running in ${kReleaseMode ? 'RELEASE' : 'DEBUG'} mode.");

    globalNotifierCounter.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _destinations = [
      ...widget.config?.destinationsBuilder(context) ?? [],
      NavigationDestination(
        selectedIcon: Icon(Icons.settings),
        icon: Icon(Icons.settings_outlined),
        label: AppLocalizations.of(context)!.settings,
      ),
    ];

    if (globalNotifierCounter.value >= 7 && !kIsWeb) {
      globalNotifierCounter.value = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          globalAppName![0].toUpperCase() +
              globalAppName!.substring(1).toLowerCase(),
          style: TextStyle(
            fontFamily: 'The Hand',
            fontSize: 36,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentPageIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.config?.bottomBar != null) widget.config!.bottomBar!,
          NavigationBar(
            onDestinationSelected: (int index) {
              setState(() => _currentPageIndex = index);
            },
            selectedIndex: _currentPageIndex,
            destinations: _destinations,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    globalNotifierCounter.removeListener(_updateState);
    super.dispose();
  }
}
