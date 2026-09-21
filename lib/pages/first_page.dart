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

  /// Opt in to a private [Navigator] per tab, so a route pushed inside a tab
  /// has something for the system back button to pop instead of exiting the
  /// app.
  ///
  /// Defaults to **false** so existing apps are byte-for-byte unchanged until
  /// they ask for it — this is a shared package, and where a plain
  /// `Navigator.push` lands (inside the tab, under the bottom bar, instead of
  /// covering it) is not something an app should inherit without deciding.
  /// Measured across the fleet: auraninja has one `Navigator.push` site,
  /// decisioninja none, tvninja three, and nothing today uses
  /// `rootNavigator` — turning this on unconditionally would silently
  /// relocate auraninja's one push.
  ///
  /// Only the visible tab's nested [Navigator] is allowed to veto a system
  /// back press; a hidden tab's stack is left untouched.
  final bool nestedNavigation;

  /// App-specific rows appended to the shared [SettingsPage].
  ///
  /// Without this there is no way at all for an app to add a preference: the
  /// settings page is shared and was previously closed, so each app got an
  /// identical screen or none of its own.
  final List<Widget>? extraSettings;

  const FirstPageConfig({
    required this.destinationsBuilder,
    required this.pages,
    this.bottomBar,
    this.topBarBuilder,
    this.sideBySidePlayerBuilder,
    this.hasActivePlayerBuilder,
    this.responsiveNavigation = false,
    this.nestedNavigation = false,
    this.extraSettings,
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
  late String _formattedAppName;

  /// Keeps every page's `State` alive when the layout re-parents the stack.
  ///
  /// `bodyContent` below is built one way and then, when the rail turns on,
  /// **wrapped in an extra `Row`**. That moves the `IndexedStack` to a different
  /// position in the element tree, and Flutter cannot match an element across a
  /// changed position — so it discards the subtree and builds a fresh one,
  /// taking every page's `State` with it.
  ///
  /// Measured in tvninja before this key existed: open a playlist's channel
  /// list in portrait, rotate past the 600px breakpoint, and the page is back
  /// at the playlist list — the selection, the search box and the group filter
  /// all reset. It looked like a navigation bug in the app; it was this.
  ///
  /// A `GlobalKey` makes the element *move* instead of being recreated. One key
  /// is shared by both branches below deliberately: they are mutually exclusive
  /// (`useRail` requires `!useSideBySide`), so it is never in the tree twice,
  /// and sharing it means switching to the side-by-side layout preserves state
  /// too.
  final GlobalKey _pagesKey = GlobalKey();

  /// One nested-Navigator key per entry in [_pages] (including the appended
  /// [SettingsPage]), used only when [FirstPageConfig.nestedNavigation] is
  /// on. Allocated once in [initState] rather than per build, since a
  /// [GlobalKey] must stay stable across the widget's lifetime.
  late final List<GlobalKey<NavigatorState>> _tabNavigatorKeys;

  @override
  void initState() {
    super.initState();

    _formattedAppName = globalFormattedAppName;

    _pages = [
      ...widget.config?.pages ?? [],
      SettingsPage(extraSettings: widget.config?.extraSettings),
    ];

    _tabNavigatorKeys =
        List.generate(_pages.length, (_) => GlobalKey<NavigatorState>());

    debugPrint("🔍 Running in ${kReleaseMode ? 'RELEASE' : 'DEBUG'} mode.");

    globalNotifierCounter.addListener(_onCounterChanged);
  }

  void _onCounterChanged() {
    globalNotifierCounter.value = 0;
  }

  /// Compact tab bar shown at the top of the right content panel in landscape.
  /// Replaces the bottom NavigationBar so users can still switch tabs without
  /// rotating back to portrait.
  Widget _buildLandscapeTabBar(
    ThemeData theme,
    List<NavigationDestination> destinations,
  ) {
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
        children: List.generate(destinations.length, (index) {
          final dest = destinations[index];
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

    final destinations = <NavigationDestination>[
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

    // With `nestedNavigation` off, each entry is the app's own page widget —
    // no `Navigator`, no `NavigatorPopHandler`. See
    // FirstPageConfig.nestedNavigation.
    //
    // Every entry is wrapped in a `TickerMode` regardless of that flag; see
    // the comment on the wrapper below for why. (This used to return `_pages`
    // verbatim when the flag was off, and the note here promised an unchanged
    // widget tree for apps that had not opted in — that promise is what let
    // hidden tabs keep animating, so it is deliberately no longer true.)
    final nestedNavigation = widget.config?.nestedNavigation ?? false;
    final stackPages = List<Widget>.generate(_pages.length, (i) {
      final page = !nestedNavigation
          ? _pages[i]
          : NavigatorPopHandler(
              // Only the visible tab may veto back. This is the whole reason
              // the wrapper exists — a hidden IndexedStack child stays
              // mounted (Visibility(maintainState: true)), and an
              // unconditional PopScope in it would still veto the app-level
              // pop even while offstage.
              enabled: i == _currentPageIndex,
              onPopWithResult: (_) =>
                  _tabNavigatorKeys[i].currentState?.maybePop(),
              child: Navigator(
                key: _tabNavigatorKeys[i],
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => _pages[i],
                  settings: settings,
                ),
              ),
            );

      // Mute tickers on tabs the user cannot see.
      //
      // `IndexedStack` wraps every child in `Visibility(maintainAnimation:
      // true)`, and `Visibility` only inserts a `TickerMode` when
      // `maintainAnimation` is *false* — so by default a hidden tab's
      // `AnimationController`s keep ticking and keep scheduling frames, for
      // the whole life of the app. Measured on auraninja 1.7.4 before this
      // wrapper: a completely static screen with nothing playing rendered a
      // continuous 60 fps at 4.5% CPU on Android and 60 fps on web, because
      // the visualizer page's ticker runs from launch whether or not its tab
      // was ever opened.
      //
      // `TickerProviderStateMixin` mutes its tickers when `TickerMode` is
      // off, and `Ticker.shouldScheduleTick` is `!muted && isActive &&
      // !scheduled`, so a muted ticker stops requesting frames entirely.
      //
      // This affects Flutter tickers only — audio and video keep playing,
      // since ExoPlayer/media_kit/just_audio do not drive playback from a
      // `Ticker`.
      return TickerMode(enabled: i == _currentPageIndex, child: page);
    });

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
                _buildLandscapeTabBar(theme, destinations),
                Expanded(
                  child: IndexedStack(
                    key: _pagesKey,
                    index: _currentPageIndex,
                    children: stackPages,
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
              key: _pagesKey,
              index: _currentPageIndex,
              children: stackPages,
            ),
          ),
        ],
      );
    }

    if (useRail) {
      bodyContent = Row(
        children: [
          // Deliberately NOT wrapped in a SafeArea: NavigationRail already
          // wraps its own destinations in one (see navigation_rail.dart —
          // `left`/`right` by text direction, and `top`/`bottom` omitted so
          // they default to true). Adding another changes nothing about which
          // destinations are reachable — measured identical — and only shrinks
          // the rail's Material off the screen edge, losing the edge-to-edge
          // surface the system bar is meant to sit on top of.
          NavigationRail(
            // Match NavigationBar. M3 gives them different defaults -- the bar
            // gets surfaceContainer (navigation_bar.dart:1440), the rail gets
            // surface (navigation_rail.dart:1182) -- so the same app looked
            // different either side of the 600px breakpoint: the rail blended
            // into the page while the bar read as chrome.
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            selectedIndex: _currentPageIndex,
            onDestinationSelected: (int index) {
              setState(() => _currentPageIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            // NavigationRail will not take a NavigationDestination, so the
            // shared list is mapped here. Doing it inside the package keeps
            // `destinationsBuilder`'s existing signature — apps pass exactly
            // what they pass today.
            destinations: destinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // The content, however, gets nothing for free. `bootstrap.dart` puts
          // the app edge-to-edge, so the system bars are drawn OVER it, and
          // Scaffold insets `bottomNavigationBar` but never `body`. In
          // landscape the Android navigation bar sits on a side edge, and when
          // that edge is the right one it lands on this content — nothing else
          // in the tree protects it.
          //
          // `left: false` leaves the left inset alone: the rail is what
          // occupies that edge, and it handles its own.
          Expanded(
            child: SafeArea(left: false, child: bodyContent),
          ),
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
                  destinations: destinations,
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
