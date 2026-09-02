import 'dart:async';

import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/widgets.dart';
import 'package:nonogram_daily/services/ads/ad_service.dart';

/// Ad unit IDs, sourced from `--dart-define` (never hardcoded/committed —
/// see `.env.example`). Empty strings mean "not configured", and every
/// [MaxAdService] method treats that as "this placement is off" rather
/// than erroring.
class MaxAdConfig {
  const MaxAdConfig({
    required this.sdkKey,
    required this.rewardedHintAdUnitId,
    required this.rewardedExtraHeartAdUnitId,
    required this.rewardedArchiveUnlockAdUnitId,
    required this.interstitialAdUnitId,
    required this.bannerAdUnitId,
  });

  factory MaxAdConfig.fromDartDefines() => const MaxAdConfig(
    sdkKey: String.fromEnvironment('APPLOVIN_SDK_KEY'),
    rewardedHintAdUnitId: String.fromEnvironment('AD_UNIT_REWARDED_HINT'),
    rewardedExtraHeartAdUnitId: String.fromEnvironment(
      'AD_UNIT_REWARDED_EXTRA_HEART',
    ),
    rewardedArchiveUnlockAdUnitId: String.fromEnvironment(
      'AD_UNIT_REWARDED_ARCHIVE_UNLOCK',
    ),
    interstitialAdUnitId: String.fromEnvironment('AD_UNIT_INTERSTITIAL'),
    bannerAdUnitId: String.fromEnvironment('AD_UNIT_BANNER'),
  );

  final String sdkKey;
  final String rewardedHintAdUnitId;
  final String rewardedExtraHeartAdUnitId;
  final String rewardedArchiveUnlockAdUnitId;
  final String interstitialAdUnitId;
  final String bannerAdUnitId;

  bool get isConfigured => sdkKey.isNotEmpty;
}

/// [AdService] backed by AppLovin MAX (the locked ad mediation SDK).
class MaxAdService implements AdService {
  MaxAdService(this._config);

  final MaxAdConfig _config;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (!_config.isConfigured) return;
    await AppLovinMAX.initialize(_config.sdkKey);
    _initialized = true;
    if (_config.interstitialAdUnitId.isNotEmpty) {
      AppLovinMAX.loadInterstitial(_config.interstitialAdUnitId);
    }
  }

  String _adUnitFor(RewardedPlacement placement) => switch (placement) {
    RewardedPlacement.hint => _config.rewardedHintAdUnitId,
    RewardedPlacement.extraHeart => _config.rewardedExtraHeartAdUnitId,
    RewardedPlacement.archiveUnlock => _config.rewardedArchiveUnlockAdUnitId,
  };

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async {
    if (!_initialized) return false;
    final adUnitId = _adUnitFor(placement);
    if (adUnitId.isEmpty) return false;

    final completer = Completer<bool>();
    var earnedReward = false;

    void complete({required bool result}) {
      if (!completer.isCompleted) completer.complete(result);
    }

    AppLovinMAX.setRewardedAdListener(
      RewardedAdListener(
        onAdLoadedCallback: (ad) => AppLovinMAX.showRewardedAd(adUnitId),
        onAdLoadFailedCallback: (id, error) => complete(result: false),
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) => complete(result: false),
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) => complete(result: earnedReward),
        onAdReceivedRewardCallback: (ad, reward) => earnedReward = true,
      ),
    );
    AppLovinMAX.loadRewardedAd(adUnitId);

    return completer.future;
  }

  @override
  Future<bool> showInterstitial() async {
    if (!_initialized || _config.interstitialAdUnitId.isEmpty) return false;
    final adUnitId = _config.interstitialAdUnitId;

    final completer = Completer<bool>();
    void complete({required bool result}) {
      if (!completer.isCompleted) completer.complete(result);
    }

    AppLovinMAX.setInterstitialListener(
      InterstitialListener(
        onAdLoadedCallback: (ad) {},
        onAdLoadFailedCallback: (id, error) => complete(result: false),
        onAdDisplayedCallback: (ad) => complete(result: true),
        onAdDisplayFailedCallback: (ad, error) => complete(result: false),
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {
          // Pre-load the next one so a later eligible moment isn't stuck
          // waiting on a fresh load.
          AppLovinMAX.loadInterstitial(adUnitId);
        },
      ),
    );

    final ready = await AppLovinMAX.isInterstitialReady(adUnitId) ?? false;
    if (!ready) {
      complete(result: false);
      AppLovinMAX.loadInterstitial(adUnitId);
    } else {
      AppLovinMAX.showInterstitial(adUnitId);
    }

    return completer.future;
  }

  @override
  Widget buildBanner() {
    if (!_initialized || _config.bannerAdUnitId.isEmpty) {
      return const SizedBox.shrink();
    }
    return MaxAdView(
      adUnitId: _config.bannerAdUnitId,
      adFormat: AdFormat.banner,
    );
  }
}
