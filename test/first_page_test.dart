import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_material/config/shared_config.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'package:ninja_material/pages/first_page.dart';

/// First tests in this package.
///
/// Three apps depend on `ninja_material`, so a regression here does not fail
/// one app's CI — it reaches every app, whenever each next bumps its pinned
/// `ref`. These cover the shell's navigation contract, its interaction with
/// the pre-existing side-by-side player layout, preservation of an app-supplied
/// bottomBar, and the settings extension point — the things an app cannot work
/// around if they break.
void main() {
  setUp(() {
    // FirstPage.initState reads this unconditionally.
    globalAppName = 'testapp';
  });

  FirstPageConfig config({
    bool responsiveNavigation = false,
    List<Widget>? extraSettings,
    Widget? bottomBar,
    bool hasActivePlayer = false,
  }) =>
      FirstPageConfig(
        destinationsBuilder: (_) => const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        ],
        pages: const [Center(child: Text('PAGE'))],
        responsiveNavigation: responsiveNavigation,
        extraSettings: extraSettings,
        bottomBar: bottomBar,
        sideBySidePlayerBuilder:
            hasActivePlayer ? (_) => const Center(child: Text('PLAYER')) : null,
        hasActivePlayerBuilder: hasActivePlayer ? (_) => true : null,
      );

  Future<void> pumpShell(
    WidgetTester tester, {
    required FirstPageConfig cfg,
    required Size size,
    FakeViewPadding? padding,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0; // physical == logical, so sizes read directly
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Set on the view rather than injected as a MediaQuery, so the value
    // travels the same path a real system inset does.
    if (padding != null) {
      tester.view.padding = padding;
      addTearDown(tester.view.resetPadding);
    }

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FirstPage.withConfig(config: cfg),
    ));
    await tester.pumpAndSettle();
  }

  group('FirstPage navigation', () {
    testWidgets('defaults to the bottom NavigationBar, even when wide',
        (tester) async {
      // The opt-in default matters: existing apps must be unchanged by the
      // responsive work until they ask for it.
      await pumpShell(tester, cfg: config(), size: const Size(1200, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('renders a NavigationRail when opted in and wide',
        (tester) async {
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(1000, 800),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('keeps the bottom bar when opted in but narrow',
        (tester) async {
      // Width, not orientation, and not the opt-in alone: a narrow viewport
      // keeps the bar however the app is configured.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(400, 800),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('rail stands down under the side-by-side player layout',
        (tester) async {
      // The riskiest interaction in the change: FirstPage already had a
      // landscape mode with its own navigation (_buildLandscapeTabBar). This
      // size is landscape AND past the rail breakpoint, so without the
      // !useSideBySide guard both would try to own navigation at once.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true, hasActivePlayer: true),
        size: const Size(1000, 600),
      );

      expect(find.text('PLAYER'), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      // Side-by-side hides the bottom bar too — its own tab bar replaces it.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('an app-supplied bottomBar survives the rail swap',
        (tester) async {
      // bottomBar is a real app widget (auraninja's player bar). The rail
      // replaces the NavigationBar only; taking the whole bottomNavigationBar
      // slot would silently delete a feature.
      await pumpShell(
        tester,
        cfg: config(
          responsiveNavigation: true,
          bottomBar: const SizedBox(
            height: 40,
            child: Center(child: Text('APP BOTTOM BAR')),
          ),
        ),
        size: const Size(1000, 800),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('APP BOTTOM BAR'), findsOneWidget);
    });

    testWidgets('rail carries every destination, including the appended one',
        (tester) async {
      // FirstPage appends Settings itself, so an app supplying one destination
      // must end up with two. Guards the NavigationDestination ->
      // NavigationRailDestination mapping.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(1000, 800),
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 2);
      expect(rail.selectedIndex, 0);
    });

    // bootstrap.dart runs the app edge-to-edge, so the system bars are drawn
    // OVER it, and in landscape the Android navigation bar sits on a side edge
    // — left or right depending on which way the phone was turned. Scaffold
    // insets `bottomNavigationBar` for us but never `body`, which is where the
    // rail and its content live.
    //
    // These four use asymmetric insets (left 24, right 48) so that a wrapper
    // applying the same padding to both sides cannot pass by coincidence.

    testWidgets('content beside the rail clears a right-edge system bar',
        (tester) async {
      // THE regression. Nothing else in the tree protects the content: before
      // the fix its right edge sat at 1000, flush under the bar.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(1000, 800),
        padding: const FakeViewPadding(left: 24, right: 48),
      );

      expect(tester.getTopRight(find.byType(IndexedStack)).dx, 1000 - 48);
    });

    testWidgets('content is flush when there are no system insets',
        (tester) async {
      // Pairs with the test above, so the 952 there is provably the padding
      // and not something SafeArea adds unconditionally.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(1000, 800),
      );

      expect(tester.getTopRight(find.byType(IndexedStack)).dx, 1000);
    });

    testWidgets('rail destinations clear a left-edge system bar',
        (tester) async {
      // Passes with or without our own wrapping, and that is the point:
      // NavigationRail already wraps its destinations in a SafeArea of its
      // own. This pins that behaviour so a future Flutter bump (or someone
      // restructuring the Row) cannot quietly push the icons under the bar.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(1000, 800),
        padding: const FakeViewPadding(left: 24, right: 48),
      );

      expect(
        tester.getTopLeft(find.byIcon(Icons.home)).dx,
        greaterThanOrEqualTo(24),
      );
    });

    testWidgets('rail surface stays flush against the screen edge',
        (tester) async {
      // Deliberate, and the reason the rail is NOT wrapped in a SafeArea here.
      // Wrapping it moved the rail's Material inward off the edge (measured:
      // left 0 -> 24, bottom 400 -> 340) while leaving every destination
      // exactly where it already was — all cost, no reachability gain. The
      // system bar is meant to sit on top of an edge-to-edge surface.
      //
      // So this failing is the signal that someone re-added that wrapper.
      await pumpShell(
        tester,
        cfg: config(responsiveNavigation: true),
        size: const Size(1000, 800),
        padding: const FakeViewPadding(left: 24, right: 48),
      );

      expect(tester.getTopLeft(find.byType(NavigationRail)).dx, 0);
    });
  });

  group('SettingsPage extension point', () {
    testWidgets('app-supplied extraSettings reach the settings page',
        (tester) async {
      await pumpShell(
        tester,
        cfg: config(
          extraSettings: const [ListTile(title: Text('APP SPECIFIC ROW'))],
        ),
        size: const Size(400, 800),
      );

      // The settings page lives in an IndexedStack, so it is built but
      // offstage until selected — hence skipOffstage: false.
      expect(
        find.text('APP SPECIFIC ROW', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('no extraSettings renders nothing extra', (tester) async {
      await pumpShell(tester, cfg: config(), size: const Size(400, 800));

      expect(find.text('APP SPECIFIC ROW', skipOffstage: false), findsNothing);
    });
  });
}
