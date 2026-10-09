import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/export_format.dart';

enum AppQuality { high, standard }

extension AppQualityValue on AppQuality {
  /// JPEG quality value used for export; irrelevant for PNG.
  int get value => this == AppQuality.high ? 95 : 70;
  String get label => this == AppQuality.high ? 'High' : 'Standard';
}

/// Single in-memory + persisted store for the app's four Settings
/// values. Loaded once at startup (before runApp) so every screen can
/// read current values synchronously; writes persist immediately and
/// notify listeners once persistence completes, so any screen can
/// listen via ListenableBuilder and rebuild at the correct time.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _keyThemeMode = 'theme_mode';
  static const _keyExportFormat = 'export_format';
  static const _keyExportQuality = 'export_quality';
  static const _keyHaptics = 'haptics_enabled';

  ThemeMode themeMode = ThemeMode.system;
  ExportFormat exportFormat = ExportFormat.jpg;
  AppQuality quality = AppQuality.high;
  bool hapticsEnabled = true;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      themeMode = ThemeMode.values[themeIndex];
    }

    final formatStr = prefs.getString(_keyExportFormat);
    exportFormat = formatStr == 'png' ? ExportFormat.png : ExportFormat.jpg;

    final qualityStr = prefs.getString(_keyExportQuality);
    quality = qualityStr == 'standard' ? AppQuality.standard : AppQuality.high;

    hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;

    _loaded = true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setExportFormat(ExportFormat format) async {
    exportFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyExportFormat, format == ExportFormat.png ? 'png' : 'jpg');
    notifyListeners();
  }

  Future<void> setQuality(AppQuality q) async {
    quality = q;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyExportQuality, q == AppQuality.standard ? 'standard' : 'high');
    notifyListeners();
  }

  Future<void> setHaptics(bool enabled) async {
    hapticsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptics, enabled);
    notifyListeners();
  }
}
