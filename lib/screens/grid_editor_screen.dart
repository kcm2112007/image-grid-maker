import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../services/image_service.dart';
import '../widgets/layout_selector.dart';
import '../widgets/ratio_selector.dart';
import 'framing_screen.dart';

class GridEditorScreen extends StatefulWidget {
  const GridEditorScreen({super.key});

  @override
  State<GridEditorScreen> createState() => _GridEditorScreenState();
}

class _GridEditorScreenState extends State<GridEditorScreen> {
  final ImageService _imageService = ImageService();
  GridLayoutOption _layout = kGridLayouts[1]; // default 2x2
  CanvasRatioOption _ratio = kCanvasRatios[0]; // default Square
  bool _isPicking = false;

  Future<void> _pickAndFrame() async {
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FramingScreen(
            image: result.image!,
            layout: _layout,
            canvasRatio: _ratio,
          ),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Grid')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Canvas shape',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              RatioSelector(
                selected: _ratio,
                onChanged: (r) => setState(() => _ratio = r),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose how many pieces to split your photo into',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              LayoutSelector(
                selected: _layout,
                onChanged: (l) => setState(() => _layout = l),
              ),
              const SizedBox(height: 12),
              Text(
                '${_layout.cellCount} tiles (${_layout.label})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Icon(Icons.grid_view_rounded,
                  size: 96, color: Theme.of(context).colorScheme.outlineVariant),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isPicking ? null : _pickAndFrame,
                icon: _isPicking
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Choose Photo', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
