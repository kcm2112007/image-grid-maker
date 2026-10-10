import 'dart:io';
import 'package:flutter/material.dart';
import '../app.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../models/recent_project.dart';
import '../services/link_service.dart';
import '../services/recent_projects_service.dart';
import '../widgets/banner_ad_widget.dart';
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
          initialProjectId: project.id,
        ),
      ),
    ).then((_) => _loadRecentProjects());
  }

  Future<void> _confirmDeleteProject(RecentProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove project?'),
        content: const Text(
            'This only removes it from your recent list — it does not delete any photo saved to your gallery.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recentProjectsService.deleteProject(project.id);
      _loadRecentProjects();
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      bottomNavigationBar: const SafeArea(
        top: false,
        child: BannerAdWidget(),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              titleSpacing: 20,
              title: Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: 22, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Image Grid Maker',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
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
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(onCreateGrid: _openNewGrid),
                    const SizedBox(height: 32),
                    Text('Recent projects', style: Theme.of(context).textTheme.titleMedium),
                    if (_recentProjects.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to reopen · long-press to remove',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                    ],
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
                child: _EmptyProjectsState(colorScheme: colorScheme),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = _recentProjects[index];
                      return _ProjectCard(
                        project: project,
                        label: _labelFor(project),
                        onTap: () => _reopenProject(project),
                        onLongPress: () => _confirmDeleteProject(project),
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      icon: const Icon(Icons.favorite_border, size: 18),
                      label: const Text('Invite Friends'),
                      onPressed: () => LinkService.shareReferral(),
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

/// Hero section: headline, subtext, primary CTA, and a lightweight
/// layered-tiles illustration communicating "photo → grid → tiles"
/// using only Transform/Stack/BoxShadow — no new packages.
class _HeroCard extends StatelessWidget {
  final VoidCallback onCreateGrid;
  const _HeroCard({required this.onCreateGrid});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const _TileSplitIllustration(),
          const SizedBox(height: 20),
          Text(
            'Split any photo into a grid',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Perfect for Instagram, Story grids, and more',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Create Grid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              onPressed: onCreateGrid,
            ),
          ),
        ],
      ),
    );
  }
}

/// A central "photo" card with three smaller tiles fanned out behind
/// it at slight rotations/offsets, animating in once on build. Purely
/// decorative — communicates the app's purpose without text.
class _TileSplitIllustration extends StatelessWidget {
  const _TileSplitIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: 140,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 12),
              child: child,
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            _tile(angle: -0.18, dx: -34, dy: 6, size: 54, opacity: 0.55),
            _tile(angle: 0.16, dx: 32, dy: -6, size: 54, opacity: 0.7),
            _tile(angle: 0, dx: 0, dy: 0, size: 70, opacity: 1),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required double angle,
    required double dx,
    required double dy,
    required double size,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Icon(
            Icons.grid_view_rounded,
            color: Colors.black.withValues(alpha: 0.18 * opacity + 0.1),
            size: size * 0.42,
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final RecentProject project;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProjectCard({
    required this.project,
    required this.label,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          children: [
            Expanded(
              child: Image.file(
                File(project.imagePath),
                // Keyed to the path itself, so a project update (which
                // now always produces a new file path) is never
                // mistaken for "the same image" by Flutter's widget
                // reconciliation — this forces a genuinely fresh
                // decode instead of reusing a stale cached frame.
                key: ValueKey(project.imagePath),
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
                label,
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
  }
}

class _EmptyProjectsState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyProjectsState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(14, -4),
                child: Transform.rotate(
                  angle: 0.1,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Icon(Icons.image_outlined, size: 26, color: colorScheme.outline),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first image grid to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
