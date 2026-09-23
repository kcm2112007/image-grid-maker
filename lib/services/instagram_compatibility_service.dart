import 'dart:ui' as ui;

/// Ensures a tile's aspect ratio falls within the range Instagram
/// actually displays without cropping (roughly 4:5 to 1.91:1). Grid
/// math can produce tiles narrower or wider than that range — this
/// never crops, stretches, or removes any content; it only adds solid
/// padding bars around the full, untouched tile so the whole image
/// still displays intact when posted. This only runs at export time
/// (Save/Share) — the in-app preview always shows the true, unpadded
/// tile exactly as generated.
class InstagramCompatibilityService {
  static const double _minRatio = 0.8; // 4:5
  static const double _maxRatio = 1.91; // 1.91:1

  static Future<ui.Image> letterboxForInstagram(
    ui.Image tile, {
    ui.Color padColor = const ui.Color(0xFFFFFFFF),
  }) async {
    final ratio = tile.width / tile.height;

    if (ratio >= _minRatio && ratio <= _maxRatio) {
      // Already within Instagram's range — no change needed.
      return tile;
    }

    double outputWidth = tile.width.toDouble();
    double outputHeight = tile.height.toDouble();

    if (ratio < _minRatio) {
      // Too tall/narrow — widen the canvas, pad left and right.
      outputWidth = outputHeight * _minRatio;
    } else {
      // Too wide/short — heighten the canvas, pad top and bottom.
      outputHeight = outputWidth / _maxRatio;
    }

    final offsetX = (outputWidth - tile.width) / 2;
    final offsetY = (outputHeight - tile.height) / 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, outputWidth, outputHeight),
    );

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, outputWidth, outputHeight),
      ui.Paint()..color = padColor,
    );
    canvas.drawImage(tile, ui.Offset(offsetX, offsetY), ui.Paint());

    final picture = recorder.endRecording();
    return picture.toImage(outputWidth.round(), outputHeight.round());
  }
}
