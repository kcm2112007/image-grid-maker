import 'package:flutter/material.dart';

/// Minimal, recognizable WhatsApp and Facebook glyphs drawn as vector
/// paths — not copied images or a third-party icon font. Uses only
/// plain shape drawing (no saveLayer/BlendMode), since an earlier
/// version's layer-based knockout technique caused a rendering defect
/// elsewhere on the Home screen.
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
    final bubblePaint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer bubble.
    canvas.drawCircle(center, radius, bubblePaint);

    // Speech-bubble "tail".
    final tailPath = Path()
      ..moveTo(center.dx - radius * 0.15, center.dy + radius * 0.78)
      ..lineTo(center.dx - radius * 0.55, center.dy + radius * 0.98)
      ..lineTo(center.dx - radius * 0.3, center.dy + radius * 0.5)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);

    // Handset glyph drawn directly in white on top — no knockout.
    final r = radius * 0.5;
    final handsetPath = Path();
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

    canvas.drawCircle(
      Offset(center.dx + r * 0.62, center.dy - r * 0.55),
      size.width * 0.045,
      Paint()..color = Colors.white,
    );
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

    final fPaint = Paint()..color = Colors.white;
    final w = size.width;
    final h = size.height;

    final stem = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.46, h * 0.28, w * 0.18, h * 0.52),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(stem, fPaint);

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

    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.46, w * 0.34, h * 0.1),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(bar, fPaint);
  }

  @override
  bool shouldRepaint(covariant _FacebookPainter oldDelegate) => oldDelegate.color != color;
}
