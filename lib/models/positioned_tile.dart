import 'dart:ui' as ui;

/// The single authoritative numbering function. Called exactly once,
/// at tile creation time, in ImageSlicerService. Nothing downstream
/// ever calls this again — every other screen/service reads the
/// number directly off the tile via tile.gridNumber.
int getGridNumber({
  required int row,
  required int column,
  required int rows,
  required int columns,
}) {
  return (rows - 1 - row) * columns + (columns - column);
}

/// A single generated tile. gridNumber is computed ONCE, at creation,
/// and travels permanently attached to this exact tile/image — it is
/// never recalculated, resorted by, or looked up separately anywhere
/// else in the app. Preview, "Your Grids", and export all just read
/// tile.gridNumber directly.
class PositionedTile {
  final ui.Image image;
  final int row;
  final int column;
  final int gridNumber;

  const PositionedTile({
    required this.image,
    required this.row,
    required this.column,
    required this.gridNumber,
  });
}
