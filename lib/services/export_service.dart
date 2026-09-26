import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Sorts the actual tile objects (image + position together) by
  /// their true posting number — bottom-right = 1, right-to-left,
  /// then upward row by row. This never separates image data from
  /// its number: each tile computes its own number from its own
  /// row/column, then the list of complete tile objects is sorted.
  static List<PositionedTile> _postingOrdered(
    List<PositionedTile> tiles, {
    required int rows,
    required int columns,
  }) {
    final ordered = List<PositionedTile>.from(tiles);
    ordered.sort((a, b) => a
        .postingNumber(rows, columns)
        .compareTo(b.postingNumber(rows, columns)));
    return ordered;
  }

  static String _filenameFor(int postingNumber, int total) {
    final width = total.toString().length.clamp(2, 10);
    return 'Grid_${postingNumber.toString().padLeft(width, '0')}';
  }

  /// Saves tiles to the gallery in true posting-number order, one at
  /// a time (never concurrently), so both the filename and the
  /// MediaStore insertion sequence are fully deterministic.
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

      final ordered = _postingOrdered(tiles, rows: rows, columns: columns);
      // ---- TEMPORARY DEBUG LOGGING — remove after diagnosis ----
      final docsDir = await getApplicationDocumentsDirectory();
      final logFile = File('${docsDir.path}/export_debug_log.txt');
      await logFile.writeAsString(
        'EXPORT SESSION\nrows=$rows columns=$columns totalTiles=${ordered.length}\n---\n',
        mode: FileMode.write,
      );
      // ---- END TEMPORARY SETUP ----

      // ---- TEMPORARY DEBUG LOGGING — remove after diagnosis ----
      // Nothing below this comment changes sorting, the postingNumber
      // formula, or the filename logic. It only records, for each
      // tile actually passed to Gal.putImageBytes, exactly which
      // physical tile it is and what it was named.
      final debugLog = StringBuffer();
      debugLog.writeln('EXPORT SESSION START');
      debugLog.writeln('rows=$rows columns=$columns totalTiles=${ordered.length}');
      debugLog.writeln('---');
      int saveOrderCounter = 0;
      // ---- END TEMPORARY SETUP ----

      for (final tile in ordered) {
        final postingNumber = tile.postingNumber(rows, columns);
        final filename = _filenameFor(postingNumber, ordered.length);
        final exportReadyTile =
            await InstagramCompatibilityService.letterboxForInstagram(tile.image);
        final bytes = await _imageToBytes(exportReadyTile, format: format, quality: quality);

        // ---- TEMPORARY DEBUG LOGGING ----
        saveOrderCounter++;
        debugLog.writeln('EXPORT:');
        debugLog.writeln('  rows=$rows columns=$columns');
        debugLog.writeln('  tile.row=${tile.row} tile.column=${tile.column}');
        debugLog.writeln('  postingNumber=$postingNumber');
        debugLog.writeln('  filename=$filename.${format.fileExtension}');
        debugLog.writeln('  imageIdentity=${identityHashCode(tile.image)}');
        debugLog.writeln('  sourceTileImage.width=${tile.image.width} height=${tile.image.height}');
        debugLog.writeln('  exportReadyImage.width=${exportReadyTile.width} height=${exportReadyTile.height}');
        debugLog.writeln('  startOrder=$saveOrderCounter');
        // ---- END TEMPORARY LOGGING ----

        await Gal.putImageBytes(
          bytes,
          name: filename,
        );
        saved++;

        // ---- TEMPORARY DEBUG LOGGING ----
        debugLog.writeln('SAVE COMPLETE:');
        debugLog.writeln('  filename=$filename.${format.fileExtension}');
        debugLog.writeln('  completeOrder=$saveOrderCounter');
        debugLog.writeln('---');
        // ---- END TEMPORARY LOGGING ----
      }

      // ---- TEMPORARY DEBUG LOGGING — writes log to a file and opens
      // the share sheet so it can be viewed without a PC/adb. ----
      try {
        final tempDir = await getTemporaryDirectory();
        final logFile = File('${tempDir.path}/export_debug_log.txt');
        await logFile.writeAsString(debugLog.toString());
        await Share.shareXFiles(
          [XFile(logFile.path)],
          text: 'Export debug log',
        );
      } catch (_) {
        // If sharing the log fails, don't let that affect the actual
        // export result below.
      }
      // ---- END TEMPORARY LOGGING ----

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

  /// Writes tiles to a temp folder in the same true posting order and
  /// filename convention as saveAllToGallery — Save and Share can
  /// never disagree, since both call this same sorting logic.
  static Future<ExportResult> prepareFilesForSharing(
    List<PositionedTile> tiles, {
    required int rows,
    required int columns,
    required ExportFormat format,
    int quality = 90,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ordered = _postingOrdered(tiles, rows: rows, columns: columns);
      final files = <File>[];

      for (final tile in ordered) {
        final postingNumber = tile.postingNumber(rows, columns);
        final exportReadyTile =
            await InstagramCompatibilityService.letterboxForInstagram(tile.image);
        final bytes = await _imageToBytes(exportReadyTile, format: format, quality: quality);
        final name = _filenameFor(postingNumber, ordered.length);
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
