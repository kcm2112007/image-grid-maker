import 'package:flutter/material.dart';
import '../models/grid_layout.dart';

class LayoutSelector extends StatelessWidget {
  final GridLayoutOption selected;
  final ValueChanged<GridLayoutOption> onChanged;

  const LayoutSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kGridLayouts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final layout = kGridLayouts[index];
          final isSelected = layout.id == selected.id;
          return ChoiceChip(
            label: Text(layout.label),
            selected: isSelected,
            onSelected: (_) => onChanged(layout),
          );
        },
      ),
    );
  }
}
