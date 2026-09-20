import 'package:flutter/material.dart';
import '../models/canvas_ratio.dart';

class RatioSelector extends StatelessWidget {
  final CanvasRatioOption selected;
  final ValueChanged<CanvasRatioOption> onChanged;

  const RatioSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kCanvasRatios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ratio = kCanvasRatios[index];
          final isSelected = ratio.id == selected.id;
          return ChoiceChip(
            label: Text(ratio.label),
            selected: isSelected,
            onSelected: (_) => onChanged(ratio),
          );
        },
      ),
    );
  }
}
