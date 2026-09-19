import 'package:flutter/material.dart';
import '../app.dart';
import 'grid_editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final ThemeController themeController;
  const HomeScreen({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Grid Maker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(themeController: themeController),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.grid_view_rounded,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Turn your photos into a grid',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Create Grid', style: TextStyle(fontSize: 16)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GridEditorScreen()),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 12),
              Text('Recent projects', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_outlined,
                          size: 40, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 8),
                      Text(
                        'No projects yet.\nTap "Create Grid" to make your first one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
