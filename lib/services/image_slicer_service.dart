import 'dart:developer' as developer;
import 'dart:ui' as ui;
import '../models/positioned_tile.dart';

/// Slices a single composited image into equal tiles. Each tile's
/// gridNumber is computed exactly once, right here, and attached
/// permanently to the tile — no other part of the app ever
/// recalculates or reassigns it.
class ImageSlicerService {
  static Future<List<PositionedTile>> sliceImage(
    ui.Image source, {
    required int rows,
    required int columns,
  }) async {
    final tileWidth = source.width / columns;
    final tileHeight = source.height / rows;
    final tiles = <PositionedTile>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final srcRect = ui.Rect.fromLTWH(
          c * tileWidth,
          r * tileHeight,
          tileWidth,
          tileHeight,
        );
        final dstRect = ui.Rect.fromLTWH(0, 0, tileWidth, tileHeight);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder, dstRect);
        canvas.drawImageRect(source, srcRect, dstRect, ui.Paint());
        final picture = recorder.endRecording();

        final tileImage = await picture.toImage(
          tileWidth.round(),
          tileHeight.round(),
        );

        final gridNumber = getGridNumber(row: r, column: c, rows: rows, columns: columns);

        final tile = PositionedTile(
          image: tileImage,
          row: r,
          column: c,
          gridNumber: gridNumber,
        );

        // ---- TEMPORARY DEBUG LOGGING — remove after diagnosis ----
        developer.log(
          'CREATED_TILE\n'
          'gridNumber=$gridNumber\n'
          'row=$r\n'
          'column=$c\n'
          'imageIdentity=${identityHashCode(tileImage)}',
          name: 'ImageGridMaker',
        );
        // ---- END TEMPORARY LOGGING ----

        tiles.add(tile);
      }
    }

    return tiles;
  }
}
