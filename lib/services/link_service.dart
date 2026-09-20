import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkService {
  /// Opens a URL in an external app/browser. Returns false if it could
  /// not be launched, so the caller can show a real error instead of
  /// failing silently.
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Shares a referral message for the app. There is no Play Store
  /// listing yet (release hasn't happened), so this shares a plain
  /// description for now. Replace with the real Play Store link once
  /// the app is published.
  static Future<void> shareReferral() async {
    await Share.share(
      'Check out Image Grid Maker — split any photo into a grid of tiles '
      'for Instagram or wherever you like, right from your phone!',
    );
  }
}
