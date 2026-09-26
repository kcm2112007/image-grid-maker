import 'dart:ui' as ui;

/// The single authoritative numbering function used everywhere in the
/// app — Preview, "Your Grids", filenames, and save order all call
/// this exact function with the same inputs. row=0 is the top row,
/// column=0 is the left column. Bottom-right always receives 1;
/// numbering proceeds right-to-left, then moves up a row.
int getGridNumber({
  required int row,
  required int column,
  required int rows,
  required int columns,
}) {
  return (rows - 1 - row) * columns + (columns - column);
}

/// A single generated tile with its grid position explicitly attached.
class PositionedTile {
  final ui.Image image;
  final int row;
  final int column;

  const PositionedTile({
    required this.image,
    required this.row,
    required this.column,
  });

  int postingNumber(int totalRows, int totalColumns) {
    return getGridNumber(
      row: row,
      column: column,
      rows: totalRows,
      columns: totalColumns,
    );
  }
}
