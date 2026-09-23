import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/export_format.dart';
import 'posting_order_service.dart';
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

  /// Zero-padded, sortable filename base — e.g. "Grid_01" — where the
  /// number reflects posting order (already applied to the list
  /// before this is called), not visual/reading order.
  static String _filenameFor(int postingIndexZeroBased, int total) {
    final width = total.toString().length.clamp(2, 10);
    final number = (postingIndexZeroBased + 1).toString().padLeft(width, '0');
    return 'Grid_$number';
  }

  /// Saves tiles to the gallery in Instagram posting order, one at a
  /// time (never concurrently), so MediaStore insertion order is
  /// deterministic and matches the filenames.
  static Future<ExportResult> saveAllToGallery(
    List<ui.Image> visualTiles, {
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

      final orderedTiles = PostingOrderService.getPostingOrderedTiles(visualTiles);

      for (int i = 0; i < orderedTiles.length; i++) {
        final bytes = await _imageToBytes(orderedTiles[i], format: format, quality: quality);
        await Gal.putImageBytes(
          bytes,
          name: _filenameFor(i, orderedTiles.length),
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
            : 'Saved $saved of ${visualTiles.length} tiles before an error occurred: $e',
      );
    }
  }

  /// Writes tiles to a temp folder in Instagram posting order, one at
  /// a time, using the same filename convention and the same
  /// PostingOrderService as saveAllToGallery — Save and Share can
  /// never disagree on order.
  static Future<ExportResult> prepareFilesForSharing(
    List<ui.Image> visualTiles, {
    required ExportFormat format,
    int quality = 90,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final orderedTiles = PostingOrderService.getPostingOrderedTiles(visualTiles);
      final files = <File>[];

      for (int i = 0; i < orderedTiles.length; i++) {
        final bytes = await _imageToBytes(orderedTiles[i], format: format, quality: quality);
        final name = _filenameFor(i, orderedTiles.length);
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
