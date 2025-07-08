import 'dart:io';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_data.dart';

class AdMobService {
  static bool get _isTestMode => !kReleaseMode;

  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _isTestMode
          ? 'ca-app-pub-3940256099942544/6300978111' // ✅ test banner
          : currentAppBannerAdUnitId; // 🎯 your real banner
    }
    return null;
  }

  static String? get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _isTestMode
          ? 'ca-app-pub-3940256099942544/1033173712' // ✅ test interstitial
          : currentAppInterstitialAdUnitId; // 🎯 your real interstitial
    }
    return null;
  }

  static final BannerAdListener bannerListener = BannerAdListener(
    onAdLoaded: (ad) => debugPrint('✅ Banner ad loaded'),
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
      debugPrint('❌ Banner ad failed to load: $error');
    },
    onAdOpened: (ad) => debugPrint('📣 Banner ad opened'),
    onAdClosed: (ad) => debugPrint('📴 Banner ad closed'),
  );
}
