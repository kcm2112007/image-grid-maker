import 'package:flutter/material.dart';
import 'grid_overlay_painter.dart';

/// Shows a placeholder frame matching the chosen canvas ratio, with the
/// chosen grid's cut lines drawn over it. No photo is involved here —
/// this exists purely so the user can see their ratio+grid choice
/// before picking a photo.
class LiveGridPreview extends StatelessWidget {
  final double aspectRatio;
  final int rows;
  final int columns;

  const LiveGridPreview({
    super.key,
    required this.aspectRatio,
    required this.rows,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.outline, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: GridOverlayPainter(
            rows: rows,
            columns: columns,
            lineColor: colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
