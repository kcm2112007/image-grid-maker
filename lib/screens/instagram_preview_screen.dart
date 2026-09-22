import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/export_format.dart';
import '../services/export_service.dart';

/// Shows the correct order to post tiles so they line up on a profile
/// grid. Since platforms like Instagram show the newest post first
/// (top-left), the posting order is the reverse of reading order —
/// the last tile (reading order) must be posted first. The full
/// canvas shape (whatever ratio the user chose) is always shown
/// intact — never cropped to fit a fixed-shape container.
class InstagramPreviewScreen extends StatefulWidget {
  final List<ui.Image> tiles;
  final int columns;
  final int rows;
  final double canvasAspectRatio;

  const InstagramPreviewScreen({
    super.key,
    required this.tiles,
    required this.columns,
    required this.rows,
    required this.canvasAspectRatio,
  });

  @override
  State<InstagramPreviewScreen> createState() => _InstagramPreviewScreenState();
}

class _InstagramPreviewScreenState extends State<InstagramPreviewScreen> {
  bool _isSaving = false;

  int _postingOrderFor(int readingIndex) {
    return widget.tiles.length - readingIndex;
  }

  Future<void> _saveGridImages() async {
    setState(() => _isSaving = true);
    final result = await ExportService.saveAllToGallery(
      widget.tiles,
      format: ExportFormat.png,
    );
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result.error == 'PERMISSION_DENIED') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Storage access needed'),
          content: const Text('Allow gallery access to save these tiles.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Saved ${result.savedCount} tiles to your gallery.'
              : (result.error ?? 'Could not save tiles.'),
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Why this order?'),
        content: const Text(
          'Instagram (and similar apps) show your newest post at the '
          'top-left of your profile grid. To make these tiles line up '
          'into the original photo, post them starting from the tile '
          'numbered 1, then 2, 3, and so on — not in reading order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cellAspectRatio =
        widget.canvasAspectRatio * widget.rows / widget.columns;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Grids')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Tap on the photos in order of their numbers to post to your feed.',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: widget.canvasAspectRatio,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.columns,
                        childAspectRatio: cellAspectRatio,
                      ),
                      itemCount: widget.tiles.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            RawImage(image: widget.tiles[index], fit: BoxFit.cover),
                            Center(
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black38, blurRadius: 4),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${_postingOrderFor(index)}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveGridImages,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Save Grid Images'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _showHelp,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text('Help?'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
