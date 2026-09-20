import 'package:flutter/material.dart';

/// Draws the cut-lines for the chosen grid over the framing area,
/// so the user can see exactly where each tile boundary will fall
/// before exporting.
class GridOverlayPainter extends CustomPainter {
  final int rows;
  final int columns;
  final Color lineColor;

  GridOverlayPainter({
    required this.rows,
    required this.columns,
    this.lineColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.5;

    // Vertical lines between columns.
    for (int c = 1; c < columns; c++) {
      final x = size.width * c / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines between rows.
    for (int r = 1; r < rows; r++) {
      final y = size.height * r / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Outer border so the frame edge is visible even against similar
    // background colors.
    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(covariant GridOverlayPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.lineColor != lineColor;
  }
}
