/// Describes one grid layout option (e.g. 2x2). Adding a new layout later
/// is just adding one entry to `kGridLayouts` — nothing else changes.
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
  GridLayoutOption(id: '1x2', label: '1 × 2', rows: 1, columns: 2),
  GridLayoutOption(id: '2x2', label: '2 × 2', rows: 2, columns: 2),
  GridLayoutOption(id: '2x3', label: '2 × 3', rows: 2, columns: 3),
  GridLayoutOption(id: '3x3', label: '3 × 3', rows: 3, columns: 3),
  GridLayoutOption(id: '3x4', label: '3 × 4', rows: 3, columns: 4),
];
