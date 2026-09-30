import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../constants/app_constants.dart';
import '../models/export_format.dart';
import '../services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeController themeController;
  const SettingsScreen({super.key, required this.themeController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = '${info.version} (${info.buildNumber})');
  }

  Future<void> _openLink(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  void _showNotConfigured(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what has not been configured yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.themeController,
        builder: (context, currentMode, _) {
          return ListView(
            children: [
              const _SectionHeader('Appearance'),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (m) {
                  widget.themeController.setMode(m!);
                  AppSettings.instance.setThemeMode(m);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (m) {
                  widget.themeController.setMode(m!);
                  AppSettings.instance.setThemeMode(m);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (m) {
                  widget.themeController.setMode(m!);
                  AppSettings.instance.setThemeMode(m);
                },
              ),
              const Divider(),

              const _SectionHeader('Image Format'),
              RadioListTile<ExportFormat>(
                title: const Text('JPG'),
                subtitle: const Text('Used as the default in Preview\'s export options'),
                value: ExportFormat.jpg,
                groupValue: AppSettings.instance.exportFormat,
                onChanged: (f) => setState(() => AppSettings.instance.setExportFormat(f!)),
              ),
              RadioListTile<ExportFormat>(
                title: const Text('PNG'),
                value: ExportFormat.png,
                groupValue: AppSettings.instance.exportFormat,
                onChanged: (f) => setState(() => AppSettings.instance.setExportFormat(f!)),
              ),
              const Divider(),

              const _SectionHeader('Image Quality'),
              RadioListTile<AppQuality>(
                title: const Text('High'),
                subtitle: const Text('Applies to JPG export'),
                value: AppQuality.high,
                groupValue: AppSettings.instance.quality,
                onChanged: (q) => setState(() => AppSettings.instance.setQuality(q!)),
              ),
              RadioListTile<AppQuality>(
                title: const Text('Standard'),
                subtitle: const Text('Smaller file size'),
                value: AppQuality.standard,
                groupValue: AppSettings.instance.quality,
                onChanged: (q) => setState(() => AppSettings.instance.setQuality(q!)),
              ),
              const Divider(),

              const _SectionHeader('Haptic Feedback'),
              SwitchListTile(
                title: const Text('Vibrate on save/export'),
                value: AppSettings.instance.hapticsEnabled,
                onChanged: (v) => setState(() => AppSettings.instance.setHaptics(v)),
              ),
              const Divider(),

              const _SectionHeader('About'),
              ListTile(
                title: const Text('App Version'),
                subtitle: Text(_version.isEmpty ? 'Loading...' : _version),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (kPrivacyPolicyUrl.isEmpty) {
                    _showNotConfigured('Privacy Policy');
                  } else {
                    _openLink(kPrivacyPolicyUrl);
                  }
                },
              ),
              ListTile(
                title: const Text('Contact / Feedback'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (kContactEmail.isEmpty) {
                    _showNotConfigured('Contact email');
                  } else {
                    _openLink('mailto:$kContactEmail');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
