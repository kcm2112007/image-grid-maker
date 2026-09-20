import 'dart:io';
import 'package:flutter/material.dart';
import '../models/grid_layout.dart';
import '../widgets/grid_overlay_painter.dart';

/// Lets the user pan and zoom their photo inside a frame shaped for the
/// chosen grid, with live grid lines showing exactly where each tile
/// boundary will fall. Since tiles are square, the frame's aspect ratio
/// is columns:rows (e.g. a 3x4 grid needs a 4:3-shaped frame).
class FramingScreen extends StatefulWidget {
  final File image;
  final GridLayoutOption layout;

  const FramingScreen({super.key, required this.image, required this.layout});

  @override
  State<FramingScreen> createState() => _FramingScreenState();
}

class _FramingScreenState extends State<FramingScreen> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameAspectRatio = widget.layout.columns / widget.layout.rows;

    return Scaffold(
      appBar: AppBar(
        title: Text('Position Photo — ${widget.layout.label}'),
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
                      InteractiveViewer(
                        transformationController: _controller,
                        minScale: 0.5,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(200),
                        child: Image.file(
                          widget.image,
                          fit: BoxFit.cover,
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
                onPressed: () {
                  // Slicing and export are built in Milestone 3.
                  // For now this confirms the framing step works end-to-end.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Framing saved. Export/slicing arrives in the next milestone.'),
                    ),
                  );
                },
                child: const Padding(
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
