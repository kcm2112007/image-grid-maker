import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/canvas_ratio.dart';
import '../models/grid_layout.dart';
import '../services/image_slicer_service.dart';
import '../widgets/grid_overlay_painter.dart';
import 'tile_preview_screen.dart';

/// Lets the user pan and zoom their photo inside a frame shaped by the
/// chosen canvas ratio, with live grid lines showing where each tile
/// boundary will fall. Since canvas ratio is independent of the grid's
/// rows/columns, tiles are not guaranteed to be square.
class FramingScreen extends StatefulWidget {
  final File image;
  final GridLayoutOption layout;
  final CanvasRatioOption canvasRatio;

  const FramingScreen({
    super.key,
    required this.image,
    required this.layout,
    required this.canvasRatio,
  });

  @override
  State<FramingScreen> createState() => _FramingScreenState();
}

class _FramingScreenState extends State<FramingScreen> {
  final TransformationController _controller = TransformationController();
  final GlobalKey _captureKey = GlobalKey();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        rows: widget.layout.rows,
        columns: widget.layout.columns,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TilePreviewScreen(
            tiles: tiles,
            rows: widget.layout.rows,
            columns: widget.layout.columns,
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

  @override
  Widget build(BuildContext context) {
    final frameAspectRatio = widget.canvasRatio.ratio;

    return Scaffold(
      appBar: AppBar(
        title: Text('Position Photo — ${widget.canvasRatio.label}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: frameAspectRatio,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RepaintBoundary(
                        key: _captureKey,
                        child: InteractiveViewer(
                          transformationController: _controller,
                          minScale: 0.5,
                          maxScale: 4.0,
                          boundaryMargin: const EdgeInsets.all(200),
                          child: Image.file(
                            widget.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: GridOverlayPainter(
                            rows: widget.layout.rows,
                            columns: widget.layout.columns,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pinch to zoom, drag to reposition your photo inside the frame.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton(
                onPressed: _isProcessing ? null : _captureAndSlice,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Done Positioning'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
