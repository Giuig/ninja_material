import '../config/shared_config.dart';

String? get currentAppBannerAdUnitId {
  return globalAppName?.toLowerCase() == 'decisioninja'
      ? 'ca-app-pub-7039293790491388/3910798221'
      : globalAppName?.toLowerCase() == 'auraninja'
          ? 'ca-app-pub-7039293790491388/5999886770'
          : null;
}

String? get currentAppInterstitialAdUnitId {
  return globalAppName?.toLowerCase() == 'decisioninja'
      ? 'ca-app-pub-7039293790491388/9240281990'
      : null;
}
