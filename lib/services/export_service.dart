import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Result of an export attempt. `error` is null on full success.
/// `savedCount` tells the UI how many tiles actually succeeded, since
/// a partial failure partway through a batch is still useful to report
/// accurately rather than as a flat success/failure.
class ExportResult {
  final bool success;
  final int savedCount;
  final String? error;
  final List<File> files;

  const ExportResult({
    required this.success,
    required this.savedCount,
    this.error,
    this.files = const [],
  });
}

class ExportService {
  /// Converts a ui.Image into PNG bytes.
  static Future<Uint8List> _imageToPngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Could not encode image to PNG.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Saves every tile directly to the device's photo gallery as PNG files,
  /// numbered in the same reading order shown in the preview.
  static Future<ExportResult> saveAllToGallery(List<ui.Image> tiles) async {
    int saved = 0;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          return const ExportResult(
            success: false,
            savedCount: 0,
            error: 'PERMISSION_DENIED',
          );
        }
      }

      for (int i = 0; i < tiles.length; i++) {
        final bytes = await _imageToPngBytes(tiles[i]);
        await Gal.putImageBytes(
          bytes,
          name: 'image_grid_maker_tile_${i + 1}',
        );
        saved++;
      }

      return ExportResult(success: true, savedCount: saved);
    } catch (e) {
      return ExportResult(
        success: saved > 0,
        savedCount: saved,
        error: saved == 0
            ? 'Could not save tiles: $e'
            : 'Saved $saved of ${tiles.length} tiles before an error occurred: $e',
      );
    }
  }

  /// Writes every tile to a temp folder as PNG files, so they can be
  /// handed to the share sheet. Returns the file paths so the caller
  /// (share_plus) can attach them.
  static Future<ExportResult> prepareFilesForSharing(List<ui.Image> tiles) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = <File>[];

      for (int i = 0; i < tiles.length; i++) {
        final bytes = await _imageToPngBytes(tiles[i]);
        final file = File('${tempDir.path}/tile_${i + 1}.png');
        await file.writeAsBytes(bytes);
        files.add(file);
      }

      return ExportResult(success: true, savedCount: files.length, files: files);
    } catch (e) {
      return ExportResult(
        success: false,
        savedCount: 0,
        error: 'Could not prepare tiles for sharing: $e',
      );
    }
  }
}
