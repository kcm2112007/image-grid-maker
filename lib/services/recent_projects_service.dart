import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/recent_project.dart';

/// Persists a capped list of recent projects: a JSON manifest plus
/// copies of the original photos, both stored in the app's own
/// documents folder so they survive app restarts. Older entries beyond
/// the cap are deleted, including their copied photo files, so storage
/// doesn't grow without bound.
class RecentProjectsService {
  static const int _maxProjects = 12;
  static const String _manifestFileName = 'recent_projects.json';
  static const String _photosFolderName = 'recent_project_photos';

  Future<Directory> _photosDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/$_photosFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _manifestFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File('${docsDir.path}/$_manifestFileName');
  }

  /// Loads saved projects, newest first. Any entry whose photo file is
  /// missing is silently dropped rather than shown as broken.
  Future<List<RecentProject>> loadAll() async {
    try {
      final file = await _manifestFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final List<dynamic> rawList = jsonDecode(content) as List<dynamic>;
      final projects = rawList
          .map((e) => RecentProject.fromJson(e as Map<String, dynamic>))
          .toList();

      final valid = <RecentProject>[];
      for (final p in projects) {
        if (await File(p.imagePath).exists()) {
          valid.add(p);
        }
      }

      valid.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
      return valid;
    } catch (_) {
      // A corrupted manifest shouldn't crash the app; just start fresh.
      return [];
    }
  }

  Future<void> _writeManifest(List<RecentProject> projects) async {
    final file = await _manifestFile();
    final jsonList = projects.map((p) => p.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Copies [sourceImage] into permanent storage and adds a new entry
  /// at the top of the list. If this pushes the list past the cap,
  /// the oldest entries (and their photo files) are deleted.
  Future<void> saveProject({
    required File sourceImage,
    required String ratioId,
    required String layoutId,
  }) async {
    final photosDir = await _photosDir();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final extension = sourceImage.path.split('.').last;
    final destPath = '${photosDir.path}/$id.$extension';

    await sourceImage.copy(destPath);

    final newProject = RecentProject(
      id: id,
      imagePath: destPath,
      ratioId: ratioId,
      layoutId: layoutId,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    final current = await loadAll();
    final updated = [newProject, ...current];

    if (updated.length > _maxProjects) {
      final overflow = updated.sublist(_maxProjects);
      for (final old in overflow) {
        final oldFile = File(old.imagePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      updated.removeRange(_maxProjects, updated.length);
    }

    await _writeManifest(updated);
  }
  /// Removes a single project: deletes its copied photo file and
  /// removes its entry from the manifest.
  Future<void> deleteProject(String id) async {
    final current = await loadAll();
    final target = current.where((p) => p.id == id).toList();

    for (final project in target) {
      final file = File(project.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final updated = current.where((p) => p.id != id).toList();
    await _writeManifest(updated);
  }
}
