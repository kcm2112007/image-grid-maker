import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../services/export_service.dart';

/// Shows the sliced tiles in their grid position, numbered in reading
/// order (left-to-right, top-to-bottom), with real save-to-gallery and
/// share actions.
class TilePreviewScreen extends StatefulWidget {
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
  State<TilePreviewScreen> createState() => _TilePreviewScreenState();
}

class _TilePreviewScreenState extends State<TilePreviewScreen> {
  bool _isSaving = false;
  bool _isSharing = false;

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    final result = await ExportService.saveAllToGallery(widget.tiles);
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result.error == 'PERMISSION_DENIED') {
      _showPermissionDeniedDialog();
      return;
    }

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${result.savedCount} tiles to your gallery.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not save tiles.')),
      );
    }
  }

  Future<void> _shareTiles() async {
    setState(() => _isSharing = true);
    final result = await ExportService.prepareFilesForSharing(widget.tiles);
    setState(() => _isSharing = false);

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not prepare tiles for sharing.')),
      );
      return;
    }

    final xFiles = result.files.map((f) => XFile(f.path)).toList();
    await SharePlus.instance.share(
      ShareParams(files: xFiles, text: 'Split into ${widget.tiles.length} tiles with Image Grid Maker'),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Storage access needed'),
        content: const Text(
            'Image Grid Maker needs permission to save your tiles to the gallery.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preview — ${widget.tiles.length} tiles')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.columns,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: widget.tiles.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Positioned.fill(
                  child: RawImage(
                    image: widget.tiles[index],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSharing ? null : _shareTiles,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Share'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveToGallery,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Save to Gallery'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
