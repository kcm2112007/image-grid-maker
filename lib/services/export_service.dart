import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/export_format.dart';
import '../models/positioned_tile.dart';
import 'instagram_compatibility_service.dart';

/// Result of an export attempt. `error` is null on full success.
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
  static Future<Uint8List> _imageToBytes(
    ui.Image image, {
    required ExportFormat format,
    int quality = 90,
  }) async {
    if (format == ExportFormat.png) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not encode image to PNG.');
      }
      return byteData.buffer.asUint8List();
    }

    final rawByteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rawByteData == null) {
      throw Exception('Could not read image pixels for JPG encoding.');
    }

    final rgba = rawByteData.buffer.asUint8List();
    final decodedImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgba.buffer,
      numChannels: 4,
    );

    final jpgBytes = img.encodeJpg(decodedImage, quality: quality);
    return Uint8List.fromList(jpgBytes);
  }

  static String _filenameFor(int gridNumber, int total) {
    final width = total.toString().length.clamp(2, 10);
    return 'Grid_${gridNumber.toString().padLeft(width, '0')}';
  }

  /// Orders tiles purely by their own carried gridNumber — sorting a
  /// list of already-numbered tiles, never recalculating the number
  /// from position. Each tile's image and its gridNumber are the same
  /// object; sorting cannot separate them.
  static List<PositionedTile> _byGridNumber(List<PositionedTile> tiles) {
    final ordered = List<PositionedTile>.from(tiles);
    ordered.sort((a, b) => a.gridNumber.compareTo(b.gridNumber));
    return ordered;
  }

  /// Saves tiles to the gallery, one at a time, filename taken
  /// directly from each tile's own gridNumber.
  static Future<ExportResult> saveAllToGallery(
    List<PositionedTile> tiles, {
    required int rows,
    required int columns,
    required ExportFormat format,
    int quality = 90,
  }) async {
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

      final ordered = _byGridNumber(tiles);

      for (final tile in ordered) {
        final filename = _filenameFor(tile.gridNumber, ordered.length);

        // ---- TEMPORARY DEBUG LOGGING — remove after diagnosis ----
        developer.log(
          'SAVING_TILE\n'
          'gridNumber=${tile.gridNumber}\n'
          'row=${tile.row}\n'
          'column=${tile.column}\n'
          'filename=$filename.${format.fileExtension}\n'
          'imageIdentity=${identityHashCode(tile.image)}',
          name: 'ImageGridMaker',
        );
        // ---- END TEMPORARY LOGGING ----

        final exportReadyTile =
            await InstagramCompatibilityService.letterboxForInstagram(tile.image);
        final bytes = await _imageToBytes(exportReadyTile, format: format, quality: quality);

        await Gal.putImageBytes(
          bytes,
          name: filename,
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

  /// Same gridNumber-driven ordering and filenames as saveAllToGallery
  /// — Save and Share can never disagree.
  static Future<ExportResult> prepareFilesForSharing(
    List<PositionedTile> tiles, {
    required int rows,
    required int columns,
    required ExportFormat format,
    int quality = 90,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ordered = _byGridNumber(tiles);
      final files = <File>[];

      for (final tile in ordered) {
        final exportReadyTile =
            await InstagramCompatibilityService.letterboxForInstagram(tile.image);
        final bytes = await _imageToBytes(exportReadyTile, format: format, quality: quality);
        final name = _filenameFor(tile.gridNumber, ordered.length);
        final file = File('${tempDir.path}/$name.${format.fileExtension}');
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
