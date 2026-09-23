/// Single source of truth for the relationship between a grid's
/// columns/rows and the aspect ratio of each individual tile. The
/// user-selected "Canvas shape" is the ratio of ONE tile, not of the
/// whole combined grid — combinedAspectRatio is the shape the source
/// photo must be cropped to so that, once divided into columns × rows
/// equal pieces, every resulting tile ends up at exactly
/// tileAspectRatio. This formula must never be duplicated elsewhere;
/// every screen that needs either value reads it from here.
class GridConfig {
  final int columns;
  final int rows;
  final double tileAspectRatio;

  const GridConfig({
    required this.columns,
    required this.rows,
    required this.tileAspectRatio,
  });

  double get combinedAspectRatio => tileAspectRatio * columns / rows;

  int get totalTiles => columns * rows;
}
