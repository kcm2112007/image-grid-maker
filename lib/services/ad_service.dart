import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows interstitial ads. If an ad fails to load or show
/// (no internet, no fill, etc.), calling code should simply proceed —
/// an ad failure must never block the user's actual task.
///
/// TEST AD UNIT ID below — replace with your real AdMob interstitial
/// ad unit ID before releasing to the Play Store.
class AdService {
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  /// Starts loading an interstitial in the background, so it's ready
  /// by the time showInterstitial() is called. Safe to call multiple
  /// times — it won't double-load.
  void preloadInterstitial() {
    if (_isLoading || _interstitialAd != null) return;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoading = false;
          // Silently fails — the app continues without an ad. Not
          // logged to the user since it's not something they can act on.
        },
      ),
    );
  }

  /// Shows the preloaded interstitial if one is ready. If none is
  /// ready, this does nothing — it never blocks or delays the caller.
  Future<void> showInterstitialIfReady() async {
    final ad = _interstitialAd;
    if (ad == null) return;

    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial(); // Get the next one ready.
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preloadInterstitial();
      },
    );
    await ad.show();
  }

  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  /// Starts loading a rewarded ad in the background. Safe to call
  /// multiple times — it won't double-load.
  void preloadRewarded() {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  /// True only once a rewarded ad has actually finished loading —
  /// callers should use this to decide whether to show the reward
  /// button at all, rather than showing a button that might fail.
  bool get isRewardedReady => _rewardedAd != null;

  /// Shows the rewarded ad if ready. [onReward] is called only if the
  /// user actually watches to completion and earns the reward — never
  /// on skip or failure, so the reward stays real and earned.
  Future<void> showRewardedIfReady({required VoidCallback onReward}) async {
    final ad = _rewardedAd;
    if (ad == null) return;

    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preloadRewarded();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) => onReward(),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
