/// Describes one grid layout option. Columns are fixed at 3 to match
/// Instagram's profile grid (which always shows 3 posts per row), so
/// posting tiles in sequence lines up correctly. Only the row count
/// varies, giving taller overall grids for more tiles.
class GridLayoutOption {
  final String id;
  final String label;
  final int rows;
  final int columns;

  const GridLayoutOption({
    required this.id,
    required this.label,
    required this.rows,
    required this.columns,
  });

  int get cellCount => rows * columns;
}

const List<GridLayoutOption> kGridLayouts = [
  GridLayoutOption(id: '3x1', label: '3 × 1', rows: 1, columns: 3),
  GridLayoutOption(id: '3x2', label: '3 × 2', rows: 2, columns: 3),
  GridLayoutOption(id: '3x3', label: '3 × 3', rows: 3, columns: 3),
  GridLayoutOption(id: '3x4', label: '3 × 4', rows: 4, columns: 3),
  GridLayoutOption(id: '3x5', label: '3 × 5', rows: 5, columns: 3),
];
