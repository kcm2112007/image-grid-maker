import 'dart:ui' as ui;

/// Slices a single composited image into equal tiles, in reading order
/// (left-to-right, top-to-bottom). Each tile is cropped directly from the
/// source image, so capturing the source at a higher resolution (see
/// FramingScreen's pixelRatio) gives higher-quality tiles.
class ImageSlicerService {
  static Future<List<ui.Image>> sliceImage(
    ui.Image source, {
    required int rows,
    required int columns,
  }) async {
    final tileWidth = source.width / columns;
    final tileHeight = source.height / rows;
    final tiles = <ui.Image>[];

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
        tiles.add(tileImage);
      }
    }

    return tiles;
  }
}
