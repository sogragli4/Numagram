import 'package:flutter/material.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_session.dart';
import 'package:nonogram_daily/presentation/word/wordboard/crossword_layout.dart';

/// Draws the whole crossword grid — blocked cells, letter cells, clue
/// numbers, typed letters, the active entry's highlight, and the active
/// cell's cursor — as a single [CustomPainter]. Same "never one widget
/// per cell" reasoning as Nonogram's `BoardPainter`.
class CrosswordPainter extends CustomPainter {
  CrosswordPainter({
    required this.session,
    required this.layout,
    required this.activeEntry,
    required this.activeCell,
    required this.blockedColor,
    required this.cellColor,
    required this.gridLineColor,
    required this.textColor,
    required this.activeEntryTint,
    required this.activeCellColor,
    required this.wrongFlashColor,
    this.wrongFlashCell,
    this.wrongFlashOpacity = 0,
  });

  final CrosswordSession session;
  final CrosswordLayout layout;
  final CrosswordEntry activeEntry;
  final (int, int) activeCell;
  final Color blockedColor;
  final Color cellColor;
  final Color gridLineColor;
  final Color textColor;
  final Color activeEntryTint;
  final Color activeCellColor;
  final Color wrongFlashColor;
  final (int, int)? wrongFlashCell;
  final double wrongFlashOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final activeEntryCells = {
      for (var i = 0; i < activeEntry.length; i++) activeEntry.cellAt(i),
    };

    for (var row = 0; row < layout.height; row++) {
      for (var col = 0; col < layout.width; col++) {
        _paintCell(canvas, row, col, activeEntryCells);
      }
    }
    _paintGridLines(canvas);
    _paintWrongFlash(canvas);
  }

  void _paintCell(
    Canvas canvas,
    int row,
    int col,
    Set<(int, int)> activeEntryCells,
  ) {
    final rect = layout.cellRect(row, col);
    final solutionLetter = session.puzzle.solutionLetterAt(row, col);

    if (solutionLetter == null) {
      canvas.drawRect(rect, Paint()..color = blockedColor);
      return;
    }

    final isActiveCell = activeCell == (row, col);
    final fill = isActiveCell
        ? activeCellColor
        : activeEntryCells.contains((row, col))
        ? activeEntryTint
        : cellColor;
    canvas.drawRect(rect, Paint()..color = fill);

    final clueNumber = session.puzzle.clueNumberAt(row, col);
    if (clueNumber != null) {
      _drawText(
        canvas,
        text: '$clueNumber',
        rect: rect.deflate(2),
        fontSize: rect.width * 0.22,
        alignTopLeft: true,
      );
    }

    final typed = session.typedLetters[(row, col)];
    if (typed != null) {
      _drawText(canvas, text: typed, rect: rect, fontSize: rect.width * 0.5);
    }
  }

  void _paintGridLines(Canvas canvas) {
    final paint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1;
    for (var c = 0; c <= layout.width; c++) {
      final x = c * layout.cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, layout.totalSize.height), paint);
    }
    for (var r = 0; r <= layout.height; r++) {
      final y = r * layout.cellSize;
      canvas.drawLine(Offset(0, y), Offset(layout.totalSize.width, y), paint);
    }
  }

  void _paintWrongFlash(Canvas canvas) {
    final cell = wrongFlashCell;
    if (cell == null || wrongFlashOpacity <= 0) return;
    final (row, col) = cell;
    canvas.drawRect(
      layout.cellRect(row, col),
      Paint()..color = wrongFlashColor.withValues(alpha: wrongFlashOpacity),
    );
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Rect rect,
    required double fontSize,
    bool alignTopLeft = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: alignTopLeft ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = alignTopLeft
        ? rect.topLeft
        : Offset(
            rect.left + (rect.width - painter.width) / 2,
            rect.top + (rect.height - painter.height) / 2,
          );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CrosswordPainter oldDelegate) {
    return session != oldDelegate.session ||
        activeEntry != oldDelegate.activeEntry ||
        activeCell != oldDelegate.activeCell ||
        wrongFlashCell != oldDelegate.wrongFlashCell ||
        wrongFlashOpacity != oldDelegate.wrongFlashOpacity;
  }
}
