import 'package:flutter/material.dart';

/// Minimal, recognizable WhatsApp and Facebook glyphs drawn as vector
/// paths — not copied images or a third-party icon font. Avoids
/// reintroducing font_awesome_flutter, which previously broke this
/// project's build (its IconData subclassing is incompatible with
/// this Flutter version's sealed IconData class).
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;
  const WhatsAppIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WhatsAppPainter(color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;
  _WhatsAppPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rounded outer bubble.
    canvas.drawCircle(center, radius, paint);

    // Speech-bubble "tail".
    final tailPath = Path()
      ..moveTo(center.dx - radius * 0.15, center.dy + radius * 0.78)
      ..lineTo(center.dx - radius * 0.55, center.dy + radius * 0.98)
      ..lineTo(center.dx - radius * 0.3, center.dy + radius * 0.5)
      ..close();
    canvas.drawPath(tailPath, paint);

    // Handset glyph, knocked out of the bubble.
    final handsetPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    final layerRect = Rect.fromCircle(center: center, radius: radius);
    canvas.saveLayer(layerRect, Paint());
    canvas.drawCircle(center, radius, paint);

    final handsetPath = Path();
    final r = radius * 0.5;
    handsetPath.addArc(
      Rect.fromCircle(center: Offset(center.dx, center.dy - r * 0.15), radius: r),
      0.4,
      5.0,
    );
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(handsetPath, strokePaint);

    // Small "dot" accent representing the handset earpiece.
    canvas.drawCircle(
      Offset(center.dx + r * 0.62, center.dy - r * 0.55),
      size.width * 0.045,
      Paint()..color = Colors.white,
    );

    canvas.restore();
    canvas.saveLayer(layerRect, Paint());
    handsetPaint.blendMode = BlendMode.srcOver;
  }

  @override
  bool shouldRepaint(covariant _WhatsAppPainter oldDelegate) => oldDelegate.color != color;
}

class FacebookIcon extends StatelessWidget {
  final double size;
  final Color color;
  const FacebookIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FacebookPainter(color),
    );
  }
}

class _FacebookPainter extends CustomPainter {
  final Color color;
  _FacebookPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(rrect, paint);

    // The "f" glyph, drawn as simple rounded shapes.
    final fPaint = Paint()..color = Colors.white;
    final w = size.width;
    final h = size.height;

    // Vertical stem of the "f".
    final stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.46, h * 0.28, w * 0.18, h * 0.52),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(stem, fPaint);

    // Top curved hook of the "f".
    final hookPath = Path()
      ..moveTo(w * 0.46, h * 0.30)
      ..quadraticBezierTo(w * 0.46, h * 0.16, w * 0.62, h * 0.16)
      ..lineTo(w * 0.70, h * 0.16)
      ..lineTo(w * 0.70, h * 0.30)
      ..lineTo(w * 0.60, h * 0.30)
      ..quadraticBezierTo(w * 0.56, h * 0.30, w * 0.56, h * 0.36)
      ..lineTo(w * 0.56, h * 0.42)
      ..lineTo(w * 0.46, h * 0.42)
      ..close();
    canvas.drawPath(hookPath, fPaint);

    // Horizontal crossbar of the "f".
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.46, w * 0.34, h * 0.1),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(bar, fPaint);
  }

  @override
  bool shouldRepaint(covariant _FacebookPainter oldDelegate) => oldDelegate.color != color;
}
