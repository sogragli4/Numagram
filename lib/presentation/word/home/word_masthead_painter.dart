import 'package:flutter/material.dart';

/// Paints the word-game home screen's background: a navy-to-orange
/// vignette gradient plus a faint crossword-grid texture. No photographic
/// asset exists in this environment (same "real asset comes later" gap as
/// the app icon/splash/sound placeholders) — this stands in for one, built
/// from the brand palette itself rather than an unrelated stock image, so
/// it never looks out of place once real photography arrives.
class WordMastheadPainter extends CustomPainter {
  const WordMastheadPainter({required this.navy, required this.orange});

  final Color navy;
  final Color orange;

  static const _cellSize = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: const Alignment(0, -0.6),
      radius: 1.4,
      colors: [Color.lerp(navy, orange, 0.18)!, navy],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final gridPaint = Paint()
      ..color = orange.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += _cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += _cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WordMastheadPainter oldDelegate) =>
      oldDelegate.navy != navy || oldDelegate.orange != orange;
}
