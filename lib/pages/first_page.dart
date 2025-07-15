// ignore_for_file: non_constant_identifier_names, prefer_const_constructors, sized_box_for_whitespace
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

import '../config/global_notifier.dart';
import '../config/shared_config.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_mob_service.dart';
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
  BannerAd? _banner;
  InterstitialAd? _interstitialAd;
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

    if (!kIsWeb) {
      _createBannerAd();
      _createInterstitialAd();
    }

    globalNotifierCounter.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _createBannerAd() {
    final bannerId = AdMobService.bannerAdUnitId;
    if (bannerId == null) {
      debugPrint("⚠️ bannerAdUnitId is null. Skipping banner ad.");
      return;
    }

    _banner = BannerAd(
      size: AdSize.banner,
      adUnitId: bannerId,
      request: const AdRequest(),
      listener: AdMobService.bannerListener,
    )..load();
  }

  void _createInterstitialAd() {
    final interstitialId = AdMobService.interstitialAdUnitId;
    if (interstitialId == null) {
      debugPrint("⚠️ interstitialAdUnitId is null. Skipping interstitial ad.");
      return;
    }

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("✅ Interstitial ad loaded");
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint("❌ Interstitial ad failed: ${error.message}");
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) return;

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("ℹ️ Interstitial dismissed");
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("⚠️ Interstitial failed to show: $error");
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } catch (e) {
      debugPrint("🚨 Exception while showing interstitial ad: $e");
    }
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
      _showInterstitialAd();
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
          if (_banner != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            )
          else if (!kIsWeb)
            Container(
              height: 52,
              color: Colors.grey[300],
              child: Center(
                child: Text(
                  "No ads available",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          Expanded(
            // Using IndexedStack here to preserve the state of pages
            // when switching between them.
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
    _banner?.dispose();
    _interstitialAd?.dispose();
    globalNotifierCounter.removeListener(_updateState);
    super.dispose();
  }
}
