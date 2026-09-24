import 'dart:ui' as ui;
import '../models/positioned_tile.dart';

/// Slices a single composited image into equal tiles. Each tile
/// carries its own row/column from the moment it's created, so
/// posting-number and filename logic always operates on tiles that
/// know their true grid position — never on a bare list that could
/// drift out of sync with a separately-tracked position.
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

        tiles.add(PositionedTile(image: tileImage, row: r, column: c));
      }
    }

    return tiles;
  }
}
