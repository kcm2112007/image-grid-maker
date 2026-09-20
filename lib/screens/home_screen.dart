import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../models/recent_project.dart';
import '../models/social_link.dart';
import '../services/link_service.dart';
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

  Future<void> _openLink(String url) async {
    final ok = await LinkService.openUrl(url);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Image Grid Maker'),
              actions: [
                Tooltip(
                  message: 'Settings',
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(themeController: widget.themeController),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.grid_view_rounded, size: 48, color: colorScheme.onPrimary),
                          const SizedBox(height: 12),
                          Text(
                            'Split any photo into a grid',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Perfect for Instagram, Story grids, and more',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                                ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.onPrimary,
                              foregroundColor: colorScheme.primary,
                            ),
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text('Create Grid', style: TextStyle(fontSize: 16)),
                            ),
                            onPressed: _openNewGrid,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Recent projects', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_recentProjects.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open_outlined,
                            size: 40, color: colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          'No projects yet.\nTap "Create Grid" to make your first one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = _recentProjects[index];
                      return Material(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        elevation: 1,
                        child: InkWell(
                          onTap: () => _reopenProject(project),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.file(
                                  File(project.imagePath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: colorScheme.errorContainer,
                                      child: const Icon(Icons.broken_image_outlined),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: Text(
                                  _labelFor(project),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _recentProjects.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Invite Friends'),
                      onPressed: () => LinkService.shareReferral(),
                    ),
                    const SizedBox(height: 20),
                    Text('Connect with us', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: kSocialLinks.map((link) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Tooltip(
                            message: link.label,
                            child: IconButton(
                              icon: FaIcon(link.icon, size: 22),
                              onPressed: () => _openLink(link.url),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
