import 'package:flutter/material.dart';

/// Paints two very faint vertical "DİKEY"/"YATAY" clue-list strips down
/// the margins of the word game home screen, over the founder-supplied
/// background photo (`assets/images/word_home_background.jfif`) — pure
/// decorative flavor text, matching the founder's reference mockup,
/// painted directly on the canvas rather than as widget-tree `Text` (the
/// screen that hosts this excludes it from the semantics tree, the same
/// way the background photo itself carries no semantic meaning).
class WordHomeClueStripPainter extends CustomPainter {
  const WordHomeClueStripPainter({required this.color});

  final Color color;

  static const _acrossClues = [
    'BİR RENK',
    'GÖRME DUYUSU',
    'KIŞ MEVSİMİ',
    'BİR NOTA',
    'DENİZ DALGASI',
  ];
  static const _downClues = [
    'BİR SEBZE',
    'TATLI YİYECEK',
    'BİR HAYVAN',
    'AĞABEY',
    'BİR İÇECEK',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintStrip(canvas, size, x: 10, title: 'DİKEY', clues: _downClues);
    _paintStrip(
      canvas,
      size,
      x: size.width - 10,
      title: 'YATAY',
      clues: _acrossClues,
      alignRight: true,
    );
  }

  void _paintStrip(
    Canvas canvas,
    Size size, {
    required double x,
    required String title,
    required List<String> clues,
    bool alignRight = false,
  }) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 60);

    var dy = size.height * 0.44;
    final titleX = alignRight ? x - titlePainter.width : x;
    titlePainter.paint(canvas, Offset(titleX, dy));
    dy += titlePainter.height + 10;

    for (var i = 0; i < clues.length; i++) {
      final linePainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}. ${clues[i]}',
          style: TextStyle(color: color, fontSize: 9, height: 1.6),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: 64);
      final lineX = alignRight ? x - linePainter.width : x;
      linePainter.paint(canvas, Offset(lineX, dy));
      dy += linePainter.height + 6;
      if (dy > size.height * 0.78) break;
    }
  }

  @override
  bool shouldRepaint(covariant WordHomeClueStripPainter oldDelegate) =>
      oldDelegate.color != color;
}
