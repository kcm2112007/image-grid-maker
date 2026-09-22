import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' show Matrix4;

/// Computes the exact region of the original, full-resolution image
/// that the user framed — using the same math Flutter itself uses for
/// BoxFit.cover, combined with the user's pinch-zoom/pan matrix — and
/// renders it to a new image at native resolution. This is the single
/// source of truth for both preview and export: neither ever captures
/// a screenshot of the screen, so there is no rendering/timing/pixel-
/// ratio mismatch between what the user positioned and what gets
/// sliced into tiles.
class ImageComposerService {
  static Future<ui.Image> composeFramedImage({
    required ui.Image sourceImage,
    required Matrix4 transformMatrix,
    required double canvasAspectRatio,
  }) async {
    final imgW = sourceImage.width.toDouble();
    final imgH = sourceImage.height.toDouble();

    // Base "cover" fit, in a normalized frame of width 1 and height
    // (1 / canvasAspectRatio) — matches Flutter's own BoxFit.cover.
    const frameW = 1.0;
    final frameH = 1.0 / canvasAspectRatio;
    final s0 = math.max(frameW / imgW, frameH / imgH);
    final offsetX = (frameW - imgW * s0) / 2;
    final offsetY = (frameH - imgH * s0) / 2;

    // The extra zoom/pan the user applied via InteractiveViewer.
    final k = transformMatrix.getMaxScaleOnAxis();
    final tx = transformMatrix.storage[12];
    final ty = transformMatrix.storage[13];

    // Output resolution matched to the source image's native detail
    // on the covering axis — avoids blurry upscaling and avoids
    // unnecessarily huge canvases on very large camera photos.
    const maxOutputWidth = 3000.0;
    final outputWidth = math.min(1 / s0, maxOutputWidth);
    final outputHeight = outputWidth / canvasAspectRatio;

    final overallScale = k * s0 * outputWidth;
    final overallTranslateX = (k * offsetX + tx) * outputWidth;
    final overallTranslateY = (k * offsetY + ty) * outputWidth;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, outputWidth, outputHeight),
    );

    // Fills any area beyond the image's edges (only reachable if the
    // user zooms out past the initial framed crop) so no undefined
    // pixels ever appear, rather than leaving them uninitialized.
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, outputWidth, outputHeight),
      ui.Paint()..color = const ui.Color(0xFF000000),
    );

    canvas.save();
    canvas.translate(overallTranslateX, overallTranslateY);
    canvas.scale(overallScale);
    canvas.drawImage(sourceImage, ui.Offset.zero, ui.Paint());
    canvas.restore();

    final picture = recorder.endRecording();
    return picture.toImage(outputWidth.round(), outputHeight.round());
  }
}
