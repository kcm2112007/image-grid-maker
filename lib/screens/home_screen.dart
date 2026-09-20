import 'dart:io';
import 'package:flutter/material.dart';
import '../app.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../models/recent_project.dart';
import '../services/recent_projects_service.dart';
import 'grid_editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeController themeController;
  const HomeScreen({super.key, required this.themeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecentProjectsService _recentProjectsService = RecentProjectsService();
  List<RecentProject> _recentProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProjects();
  }

  Future<void> _loadRecentProjects() async {
    final projects = await _recentProjectsService.loadAll();
    if (!mounted) return;
    setState(() {
      _recentProjects = projects;
      _isLoading = false;
    });
  }

  void _openNewGrid() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GridEditorScreen()),
    ).then((_) => _loadRecentProjects());
  }

  void _reopenProject(RecentProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GridEditorScreen(
          initialImage: File(project.imagePath),
          initialRatioId: project.ratioId,
          initialLayoutId: project.layoutId,
        ),
      ),
    ).then((_) => _loadRecentProjects());
  }

  String _labelFor(RecentProject project) {
    final ratio = kCanvasRatios.firstWhere(
      (r) => r.id == project.ratioId,
      orElse: () => kCanvasRatios[0],
    );
    final layout = kGridLayouts.firstWhere(
      (l) => l.id == project.layoutId,
      orElse: () => kGridLayouts[1],
    );
    return '${ratio.label} · ${layout.label}';
  }

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
                builder: (_) => SettingsScreen(themeController: widget.themeController),
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
              const SizedBox(height: 12),
              Icon(Icons.grid_view_rounded,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                'Turn your photos into a grid',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Create Grid', style: TextStyle(fontSize: 16)),
                ),
                onPressed: _openNewGrid,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Recent projects', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _recentProjects.isEmpty
                        ? Center(
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
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _recentProjects.length,
                            itemBuilder: (context, index) {
                              final project = _recentProjects[index];
                              return InkWell(
                                onTap: () => _reopenProject(project),
                                borderRadius: BorderRadius.circular(10),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(project.imagePath),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Theme.of(context).colorScheme.errorContainer,
                                              child: const Icon(Icons.broken_image_outlined),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _labelFor(project),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
