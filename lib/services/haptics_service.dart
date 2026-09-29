import 'package:flutter/services.dart';
import 'app_settings.dart';

/// Minimal haptic feedback for meaningful actions only (successful
/// save/export) — never called on every tap.
class HapticsService {
  static void trigger() {
    if (AppSettings.instance.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
}
