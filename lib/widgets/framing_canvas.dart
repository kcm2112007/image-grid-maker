import 'dart:io';
import 'package:flutter/material.dart';
import 'grid_overlay_painter.dart';

/// Displays the user's actual photo, pinch/pan-able inside a frame shaped
/// by [aspectRatio], with grid lines for [rows] x [columns] drawn on top.
/// This widget is purely for on-screen positioning — final tile
/// generation reads [transformationController]'s matrix directly and
/// recomputes the exact same crop mathematically, rather than
/// capturing this widget's rendered pixels.
class FramingCanvas extends StatelessWidget {
  final File image;
  final double aspectRatio;
  final int rows;
  final int columns;
  final TransformationController transformationController;

  const FramingCanvas({
    super.key,
    required this.image,
    required this.aspectRatio,
    required this.rows,
    required this.columns,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              transformationController: transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: Image.file(image, fit: BoxFit.cover),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: GridOverlayPainter(rows: rows, columns: columns),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
