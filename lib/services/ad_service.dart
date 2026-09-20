import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows interstitial ads. If an ad fails to load or show
/// (no internet, no fill, etc.), calling code should simply proceed —
/// an ad failure must never block the user's actual task.
///
/// TEST AD UNIT ID below — replace with your real AdMob interstitial
/// ad unit ID before releasing to the Play Store.
class AdService {
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

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

  void dispose() {
    _interstitialAd?.dispose();
  }
}
