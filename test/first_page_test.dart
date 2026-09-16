import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_material/config/shared_config.dart';
import 'package:ninja_material/l10n/app_localizations.dart';
import 'package:ninja_material/pages/first_page.dart';

/// First tests in this package.
///
/// Three apps depend on `ninja_material`, so a regression here does not fail
/// one app's CI — it reaches every app, whenever each next bumps its pinned
/// `ref`. These cover the shell's navigation contract and the settings
/// extension point: the two things an app cannot work around if they break.
void main() {
  setUp(() {
    // FirstPage.initState reads this unconditionally.
    globalAppName = 'testapp';
  });

  FirstPageConfig config({
    bool responsiveNavigation = false,
    List<Widget>? extraSettings,
  }) =>
      FirstPageConfig(
        destinationsBuilder: (_) => const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        ],
        pages: const [Center(child: Text('PAGE'))],
        responsiveNavigation: responsiveNavigation,
        extraSettings: extraSettings,
      );

  Future<void> pumpShell(
    WidgetTester tester, {
    required FirstPageConfig cfg,
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0; // physical == logical, so sizes read directly
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
