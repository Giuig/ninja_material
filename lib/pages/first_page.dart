// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../config/global_notifier.dart';
import '../config/shared_config.dart';
import '../l10n/app_localizations.dart';
import 'settings_page.dart';

class FirstPageConfig {
  final List<NavigationDestination> Function(BuildContext) destinationsBuilder;
  final List<Widget> pages;
  final Widget? bottomBar;
  final Widget Function(BuildContext)? topBarBuilder;

  /// Optional player widget to show in landscape side-by-side mode
  final Widget Function(BuildContext)? sideBySidePlayerBuilder;

  /// Returns true when a player is active — used to decide side-by-side layout.
  /// Provide this from the app layer so that ninja_material stays decoupled
  /// from player-specific packages.
  final bool Function(BuildContext)? hasActivePlayerBuilder;

  /// Opt in to a [NavigationRail] on wide viewports instead of the bottom
  /// [NavigationBar].
  ///
  /// Defaults to **false** so existing apps are byte-for-byte unchanged until
  /// they ask for it — this is a shared package, and a nav bar silently moving
  /// is not something an app should inherit without deciding.
  ///
  /// Switches on **width**, not orientation: a phone in landscape and a tablet
  /// in portrait share a width and should lay out the same way. 600 is
  /// Material's compact/medium boundary.
  ///
  /// Ignored while the side-by-side player layout is active — that mode already
  /// has its own landscape navigation (see [_buildLandscapeTabBar]).
  final bool responsiveNavigation;

  const FirstPageConfig({
    required this.destinationsBuilder,
    required this.pages,
    this.bottomBar,
    this.topBarBuilder,
    this.sideBySidePlayerBuilder,
    this.hasActivePlayerBuilder,
    this.responsiveNavigation = false,
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
  late String _formattedAppName;

  @override
  void initState() {
    super.initState();

    _formattedAppName = globalAppName![0].toUpperCase() +
        globalAppName!.substring(1).toLowerCase();

    _pages = [
      ...widget.config?.pages ?? [],
      SettingsPage(),
    ];

    debugPrint("🔍 Running in ${kReleaseMode ? 'RELEASE' : 'DEBUG'} mode.");

    globalNotifierCounter.addListener(_onCounterChanged);
  }

  void _onCounterChanged() {
    globalNotifierCounter.value = 0;
  }

  /// Compact tab bar shown at the top of the right content panel in landscape.
  /// Replaces the bottom NavigationBar so users can still switch tabs without
  /// rotating back to portrait.
  Widget _buildLandscapeTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: List.generate(_destinations.length, (index) {
          final dest = _destinations[index];
          final isSelected = _currentPageIndex == index;
          final color = isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
              onTap: () => setState(() => _currentPageIndex = index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(color: color, size: 20),
                      child: isSelected
                          ? (dest.selectedIcon ?? dest.icon)
                          : dest.icon,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dest.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    _destinations = [
      ...widget.config?.destinationsBuilder(context) ?? [],
      NavigationDestination(
        selectedIcon: Icon(Icons.settings),
        icon: Icon(Icons.settings_outlined),
        label: AppLocalizations.of(context)!.settings,
      ),
    ];

    final topBar = widget.config?.topBarBuilder?.call(context);
    final sidePlayer = widget.config?.sideBySidePlayerBuilder?.call(context);

    // Ask the app layer whether the player is active (clean, no key hacks)
    final hasActivePlayer =
        widget.config?.hasActivePlayerBuilder?.call(context) ?? false;

    final orientation = MediaQuery.of(context).orientation;

    // Side-by-side only in landscape with an active player
    final useSideBySide =
        hasActivePlayer && orientation == Orientation.landscape;

    // Rail on wide viewports, when the app opted in and side-by-side is not
    // already handling landscape. MediaQuery width is the right source here
    // precisely because FirstPage IS the screen — nothing sits beside it. A
    // widget nested inside the body must read its own constraints instead,
    // since the rail makes the body narrower than the screen.
    final useRail = !useSideBySide &&
        (widget.config?.responsiveNavigation ?? false) &&
        MediaQuery.of(context).size.width >= 600;

    Widget bodyContent;
    if (useSideBySide) {
      // Cap video at 480px so it doesn't overwhelm content on tablets/wide screens
      final videoWidth =
          (MediaQuery.of(context).size.width * 0.5).clamp(0.0, 480.0);

      bodyContent = Row(
        children: [
          SizedBox(
            width: videoWidth,
            child: sidePlayer,
          ),
          Expanded(
            child: Column(
              children: [
                // Compact tab bar replaces the hidden bottom NavigationBar
                _buildLandscapeTabBar(theme),
                Expanded(
                  child: IndexedStack(
                    index: _currentPageIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      bodyContent = Column(
        children: [
          if (topBar != null) topBar,
          Expanded(
            child: IndexedStack(
              index: _currentPageIndex,
              children: _pages,
            ),
          ),
        ],
      );
    }

    if (useRail) {
      bodyContent = Row(
        children: [
          NavigationRail(
            selectedIndex: _currentPageIndex,
            onDestinationSelected: (int index) {
              setState(() => _currentPageIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            // NavigationRail will not take a NavigationDestination, so the
            // shared list is mapped here. Doing it inside the package keeps
            // `destinationsBuilder`'s existing signature — apps pass exactly
            // what they pass today.
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: bodyContent),
        ],
      );
    }

    return Scaffold(
      // Hide the AppBar in landscape side-by-side to reclaim the full screen height
      appBar: useSideBySide
          ? null
          : AppBar(
              title: Text(
                _formattedAppName,
                style: TextStyle(
                  fontFamily: 'The Hand',
                  fontSize: 36,
                ),
              ),
            ),
      body: bodyContent,
      // Hide bottom nav in landscape — the compact tab bar in the right panel
      // handles navigation instead.
      bottomNavigationBar: useSideBySide
          ? null
          : useRail
              // The rail replaces the NavigationBar, but NOT an app-supplied
              // bottomBar — that is a real widget (auraninja's player bar) and
              // dropping it would silently remove a feature.
              ? widget.config?.bottomBar
              : Column(
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
    globalNotifierCounter.removeListener(_onCounterChanged);
    super.dispose();
  }
}
