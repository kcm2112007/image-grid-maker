import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Shows the sliced tiles in their grid position, numbered in reading
/// order (left-to-right, top-to-bottom), so the user can confirm the
/// slice looks right before exporting (export is Milestone 4).
class TilePreviewScreen extends StatelessWidget {
  final List<ui.Image> tiles;
  final int rows;
  final int columns;

  const TilePreviewScreen({
    super.key,
    required this.tiles,
    required this.rows,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preview — ${tiles.length} tiles')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Positioned.fill(
                  child: RawImage(
                    image: tiles[index],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              // Real export/save-to-gallery/share is built in Milestone 4.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export/save arrives in the next milestone.')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Export'),
            ),
          ),
        ),
      ),
    );
  }
}
