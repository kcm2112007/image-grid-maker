import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/grid_layout.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import '../widgets/layout_selector.dart';
import '../widgets/selected_image_tile.dart';

class GridEditorScreen extends StatefulWidget {
  const GridEditorScreen({super.key});

  @override
  State<GridEditorScreen> createState() => _GridEditorScreenState();
}

class _GridEditorScreenState extends State<GridEditorScreen> {
  final ImageService _imageService = ImageService();
  final List<File> _images = [];
  GridLayoutOption _layout = kGridLayouts[1]; // default 2x2
  bool _isPicking = false;

  Future<void> _pickImages() async {
    setState(() => _isPicking = true);
    final remaining = kMaxImages - _images.length;
    final result = await _imageService.pickImages(remainingSlots: remaining);
    setState(() => _isPicking = false);

    if (!mounted) return;

    if (result.images.isNotEmpty) {
      setState(() => _images.addAll(result.images));
    }

    if (result.error == 'PERMISSION_DENIED') {
      _showPermissionDeniedDialog();
    } else if (result.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo access needed'),
        content: const Text(
            'Image Grid Maker needs permission to read your photos so you can add them to a grid.'),
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

  void _removeAt(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = _images.length >= kMaxImages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Grid'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_images.length}/$kMaxImages',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          LayoutSelector(
            selected: _layout,
            onChanged: (l) => setState(() => _layout = l),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _images.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_search_outlined,
                            size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 8),
                        Text('No images yet',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Tap "Add Images" to get started',
                            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _layout.columns,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _layout.cellCount,
                      itemBuilder: (context, index) {
                        if (index >= _images.length) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.add,
                                color: Theme.of(context).colorScheme.outline),
                          );
                        }
                        return SelectedImageTile(
                          file: _images[index],
                          onRemove: () => _removeAt(index),
                          onLoadError: () => _removeAt(index),
                        );
                      },
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: (_isPicking || atLimit) ? null : _pickImages,
                icon: _isPicking
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(atLimit ? 'Maximum reached' : 'Add Images'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
