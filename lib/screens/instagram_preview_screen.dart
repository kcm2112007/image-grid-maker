import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A mockup of a social profile grid, showing how these tiles would
/// look posted together. Since platforms like Instagram show the
/// newest post first (top-left), tiles must be posted in reverse
/// order — this screen says so plainly rather than implying the
/// mockup works with any posting order.
class InstagramPreviewScreen extends StatelessWidget {
  final List<ui.Image> tiles;
  final int columns;

  const InstagramPreviewScreen({
    super.key,
    required this.tiles,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text('Profile Grid Preview'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, color: Colors.grey, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Posts', value: '${tiles.length}'),
                      const _StatColumn(label: 'Followers', value: '—'),
                      const _StatColumn(label: 'Following', value: '—'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Your Name', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            color: Colors.amber.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            width: double.infinity,
            child: Text(
              'Post these in reverse order — tile ${tiles.length} first, tile 1 last — '
              'since new posts appear top-left. Posting in that order recreates this exact grid.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(Icons.grid_on, color: Colors.black),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                return RawImage(image: tiles[index], fit: BoxFit.cover);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
