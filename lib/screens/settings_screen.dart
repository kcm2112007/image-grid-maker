import 'package:flutter/material.dart';
import '../app.dart';

/// Real settings — the theme toggle actually changes the app's theme,
/// nothing here is decorative.
class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;
  const SettingsScreen({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, mode, _) {
          return ListView(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Follow system'),
                value: ThemeMode.system,
                groupValue: mode,
                onChanged: (m) => themeController.setMode(m!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: mode,
                onChanged: (m) => themeController.setMode(m!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: mode,
                onChanged: (m) => themeController.setMode(m!),
              ),
            ],
          );
        },
      ),
    );
  }
}
