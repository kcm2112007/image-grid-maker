import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../services/image_service.dart';
import '../services/image_slicer_service.dart';
import '../widgets/framing_canvas.dart';
import '../widgets/layout_selector.dart';
import '../widgets/live_grid_preview.dart';
import '../widgets/ratio_selector.dart';
import 'tile_preview_screen.dart';

class GridEditorScreen extends StatefulWidget {
  const GridEditorScreen({super.key});

  @override
  State<GridEditorScreen> createState() => _GridEditorScreenState();
}

class _GridEditorScreenState extends State<GridEditorScreen> {
  final ImageService _imageService = ImageService();
  final TransformationController _transformController = TransformationController();
  final GlobalKey _captureKey = GlobalKey();

  GridLayoutOption _layout = kGridLayouts[1]; // default 2x2
  CanvasRatioOption _ratio = kCanvasRatios[0]; // default Square
  File? _pickedImage;
  bool _isPicking = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    final result = await _imageService.pickSingleImage();
    setState(() => _isPicking = false);

    if (!mounted) return;

    if (result.error == 'PERMISSION_DENIED') {
      _showPermissionDeniedDialog();
      return;
    }

    if (result.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    if (result.image != null) {
      // Reset any previous pan/zoom when a new photo is picked.
      _transformController.value = Matrix4.identity();
      setState(() => _pickedImage = result.image);
    }
  }

  Future<void> _captureAndSlice() async {
    setState(() => _isProcessing = true);

    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not capture the framed photo.');
      }

      final ui.Image composedImage = await boundary.toImage(pixelRatio: 3.0);

      final tiles = await ImageSlicerService.sliceImage(
        composedImage,
        rows: _layout.rows,
        columns: _layout.columns,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TilePreviewScreen(
            tiles: tiles,
            rows: _layout.rows,
            columns: _layout.columns,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not slice the photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo access needed'),
        content: const Text(
            'Image Grid Maker needs permission to read your photos so you can split one into a grid.'),
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
    final hasImage = _pickedImage != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Grid')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Canvas shape',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              RatioSelector(
                selected: _ratio,
                onChanged: (r) => setState(() => _ratio = r),
              ),
              const SizedBox(height: 12),
              Text(
                'Split into',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              LayoutSelector(
                selected: _layout,
                onChanged: (l) => setState(() => _layout = l),
              ),
              const SizedBox(height: 4),
              Text(
                '${_layout.cellCount} tiles (${_layout.label})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              // Once a photo is picked, this shows the real photo,
              // pinch/pan-able. Before that, it shows an empty
              // placeholder frame so the user can see the shape.
              Expanded(
                child: Center(
                  child: hasImage
                      ? FramingCanvas(
                          image: _pickedImage!,
                          aspectRatio: _ratio.ratio,
                          rows: _layout.rows,
                          columns: _layout.columns,
                          captureKey: _captureKey,
                          transformationController: _transformController,
                        )
                      : LiveGridPreview(
                          aspectRatio: _ratio.ratio,
                          rows: _layout.rows,
                          columns: _layout.columns,
                        ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(height: 8),
                Text(
                  'Pinch to zoom, drag to reposition.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              if (!hasImage)
                FilledButton.icon(
                  onPressed: _isPicking ? null : _pickImage,
                  icon: _isPicking
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Choose Photo', style: TextStyle(fontSize: 16)),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _pickImage,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Change Photo'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isProcessing ? null : _captureAndSlice,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Done Positioning', maxLines: 1),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
