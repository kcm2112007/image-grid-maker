/// A canvas shape the user frames their photo into, independent of how
/// many rows/columns it gets sliced into. Since this is decoupled from
/// the grid, tiles are not guaranteed to be square once a non-square
/// ratio is combined with a grid whose rows/columns don't match it.
class CanvasRatioOption {
  final String id;
  final String label;
  final double ratio; // width / height

  const CanvasRatioOption({
    required this.id,
    required this.label,
    required this.ratio,
  });
}

const List<CanvasRatioOption> kCanvasRatios = [
  CanvasRatioOption(id: 'square', label: 'Square', ratio: 1.0),
  CanvasRatioOption(id: '3x4', label: '3:4', ratio: 3 / 4),
  CanvasRatioOption(id: '4x5', label: '4:5', ratio: 4 / 5),
];
