import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../services/image_composer_service.dart';
import '../services/image_service.dart';
import '../services/image_slicer_service.dart';
import '../services/recent_projects_service.dart';
import '../widgets/framing_canvas.dart';
import '../widgets/layout_selector.dart';
import '../widgets/live_grid_preview.dart';
import '../widgets/ratio_selector.dart';
import 'tile_preview_screen.dart';

class GridEditorScreen extends StatefulWidget {
  final File? initialImage;
  final String? initialRatioId;
  final String? initialLayoutId;

  const GridEditorScreen({
    super.key,
    this.initialImage,
    this.initialRatioId,
    this.initialLayoutId,
  });

  @override
  State<GridEditorScreen> createState() => _GridEditorScreenState();
}

class _GridEditorScreenState extends State<GridEditorScreen> {
  final ImageService _imageService = ImageService();
  final RecentProjectsService _recentProjectsService = RecentProjectsService();
  final TransformationController _transformController = TransformationController();

  late GridLayoutOption _layout;
  late CanvasRatioOption _ratio;
  File? _pickedImage;
  ui.Image? _decodedImage;
  bool _isPicking = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _layout = kGridLayouts.firstWhere(
      (l) => l.id == widget.initialLayoutId,
      orElse: () => kGridLayouts[1],
    );
    _ratio = kCanvasRatios.firstWhere(
      (r) => r.id == widget.initialRatioId,
      orElse: () => kCanvasRatios[0],
    );
    if (widget.initialImage != null) {
      _pickedImage = widget.initialImage;
      _decodeCurrentImage();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _decodeCurrentImage() async {
    if (_pickedImage == null) return;
    final decoded = await ImageService.decodeImageFile(_pickedImage!);
    if (!mounted) return;
    setState(() => _decodedImage = decoded);
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
      _transformController.value = Matrix4.identity();
      setState(() {
        _pickedImage = result.image;
        _decodedImage = null;
      });
      await _decodeCurrentImage();
    }
  }

  Future<void> _captureAndSlice() async {
    final decoded = _decodedImage;
    if (decoded == null) return;

    setState(() => _isProcessing = true);

    try {
      // The exact same math used for the live preview — the crop
      // rectangle here matches, pixel for pixel, what was framed.
      final composedImage = await ImageComposerService.composeFramedImage(
        sourceImage: decoded,
        transformMatrix: _transformController.value,
        canvasAspectRatio: _ratio.ratio,
      );

      final tiles = await ImageSlicerService.sliceImage(
        composedImage,
        rows: _layout.rows,
        columns: _layout.columns,
      );

      try {
        await _recentProjectsService.saveProject(
          sourceImage: _pickedImage!,
          ratioId: _ratio.id,
          layoutId: _layout.id,
        );
      } catch (_) {
        // Non-critical — proceed to the preview regardless.
      }

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: Center(
                        child: hasImage
                            ? FramingCanvas(
                                image: _pickedImage!,
                                aspectRatio: _ratio.ratio,
                                rows: _layout.rows,
                                columns: _layout.columns,
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
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: !hasImage
                    ? FilledButton.icon(
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
                    : Row(
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
                              onPressed: (_isProcessing || _decodedImage == null) ? null : _captureAndSlice,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
