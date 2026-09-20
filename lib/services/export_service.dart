import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/export_format.dart';

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
  /// Converts a ui.Image into bytes in the requested format. For JPG,
  /// [quality] (1-100) controls the lossy compression level; it is
  /// ignored for PNG, which is always lossless.
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

    // JPG path: dart:ui has no JPEG encoder, so we get raw RGBA pixels
    // from the ui.Image and hand them to the `image` package to encode.
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

  /// Saves every tile directly to the device's photo gallery, in the
  /// requested format, numbered in the same reading order shown in
  /// the preview.
  static Future<ExportResult> saveAllToGallery(
    List<ui.Image> tiles, {
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

      for (int i = 0; i < tiles.length; i++) {
        final bytes = await _imageToBytes(tiles[i], format: format, quality: quality);
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

  /// Writes every tile to a temp folder in the requested format, so
  /// they can be handed to the share sheet.
  static Future<ExportResult> prepareFilesForSharing(
    List<ui.Image> tiles, {
    required ExportFormat format,
    int quality = 90,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = <File>[];

      for (int i = 0; i < tiles.length; i++) {
        final bytes = await _imageToBytes(tiles[i], format: format, quality: quality);
        final file = File('${tempDir.path}/tile_${i + 1}.${format.fileExtension}');
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
