import 'dart:ui' as ui;

/// A single generated tile with its grid position explicitly attached,
/// so posting-number calculation and file saving always operate on
/// the correct image — never on an assumption that a separate list of
/// numbers still lines up with a separate list of images.
class PositionedTile {
  final ui.Image image;
  final int row; // 0-based, 0 = top row
  final int column; // 0-based, 0 = left column

  const PositionedTile({
    required this.image,
    required this.row,
    required this.column,
  });

  /// The number this tile must display and be saved under, per the
  /// required posting order: start at bottom-right = 1, move right to
  /// left, then bottom row upward.
  int postingNumber(int totalRows, int totalColumns) {
    return (totalRows - 1 - row) * totalColumns + (totalColumns - column);
  }
}
