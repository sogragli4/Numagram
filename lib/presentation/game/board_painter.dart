import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/theme.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/presentation/game/board_layout.dart';

/// Draws the entire board — clue gutters, grid lines, and cells — as a
/// single [CustomPainter]. Never one widget per cell: at a 15x15+ size
/// that's hundreds of widgets rebuilding on every tap, where one painter
/// repaints a single layer instead.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.session,
    required this.layout,
    required this.palette,
    required this.gridLineColor,
    required this.textColor,
    required this.backgroundColor,
    this.wrongFlashRow,
    this.wrongFlashCol,
    this.wrongFlashOpacity = 0,
  }) : super();

  final GameSession session;
  final BoardLayout layout;
  final BoardPalette palette;
  final Color gridLineColor;
  final Color textColor;
  final Color backgroundColor;
  final int? wrongFlashRow;
  final int? wrongFlashCol;
  final double wrongFlashOpacity;

  static const double _thinLineWidth = 1;
  static const double _thickLineWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final width = session.width;
    final height = session.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    _paintCompletedLineTint(canvas, width, height);
    _paintCells(canvas, width, height);
    _paintGridLines(canvas, width, height);
    _paintClueGutters(canvas, width, height);
    _paintWrongFlash(canvas);
  }

  void _paintCompletedLineTint(Canvas canvas, int width, int height) {
    final tint = Paint()
      ..color = palette.completedLineTint.withValues(alpha: 0.12);
    for (var r = 0; r < height; r++) {
      if (session.isRowComplete(r)) {
        canvas.drawRect(
          Rect.fromLTWH(
            layout.clueGutterWidth,
            layout.clueGutterHeight + r * layout.cellSize,
            layout.gridWidth,
            layout.cellSize,
          ),
          tint,
        );
      }
    }
    for (var c = 0; c < width; c++) {
      if (session.isColumnComplete(c)) {
        canvas.drawRect(
          Rect.fromLTWH(
            layout.clueGutterWidth + c * layout.cellSize,
            layout.clueGutterHeight,
            layout.cellSize,
            layout.gridHeight,
          ),
          tint,
        );
      }
    }
  }

  void _paintCells(Canvas canvas, int width, int height) {
    final fillPaint = Paint()..color = palette.filled;
    final markPaint = Paint()
      ..color = palette.markStroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        final state = session.stateAt(r, c);
        if (state == CellState.unknown) continue;
        final rect = layout.cellRect(r, c);
        if (state == CellState.filled) {
          canvas.drawRect(rect.deflate(1.5), fillPaint);
        } else {
          final inset = rect.deflate(rect.width * 0.28);
          canvas
            ..drawLine(inset.topLeft, inset.bottomRight, markPaint)
            ..drawLine(inset.topRight, inset.bottomLeft, markPaint);
        }
      }
    }
  }

  void _paintGridLines(Canvas canvas, int width, int height) {
    final thin = Paint()
      ..color = gridLineColor
      ..strokeWidth = _thinLineWidth;
    final thick = Paint()
      ..color = gridLineColor
      ..strokeWidth = _thickLineWidth;

    for (var c = 0; c <= width; c++) {
      final x = layout.clueGutterWidth + c * layout.cellSize;
      canvas.drawLine(
        Offset(x, layout.clueGutterHeight),
        Offset(x, layout.clueGutterHeight + layout.gridHeight),
        c % 5 == 0 ? thick : thin,
      );
    }
    for (var r = 0; r <= height; r++) {
      final y = layout.clueGutterHeight + r * layout.cellSize;
      canvas.drawLine(
        Offset(layout.clueGutterWidth, y),
        Offset(layout.clueGutterWidth + layout.gridWidth, y),
        r % 5 == 0 ? thick : thin,
      );
    }
  }

  void _paintClueGutters(Canvas canvas, int width, int height) {
    for (var r = 0; r < height; r++) {
      final dimmed = session.isRowComplete(r);
      _drawText(
        canvas,
        text: session.puzzle.rowClues[r].toString(),
        color: dimmed ? textColor.withValues(alpha: 0.35) : textColor,
        rect: Rect.fromLTWH(
          0,
          layout.clueGutterHeight + r * layout.cellSize,
          layout.clueGutterWidth - 6,
          layout.cellSize,
        ),
        alignRight: true,
      );
    }
    for (var c = 0; c < width; c++) {
      final dimmed = session.isColumnComplete(c);
      final clue = session.puzzle.columnClues[c];
      final text = clue.runs.isEmpty ? '0' : clue.runs.join('\n');
      _drawText(
        canvas,
        text: text,
        color: dimmed ? textColor.withValues(alpha: 0.35) : textColor,
        rect: Rect.fromLTWH(
          layout.clueGutterWidth + c * layout.cellSize,
          0,
          layout.cellSize,
          layout.clueGutterHeight - 4,
        ),
        alignBottom: true,
      );
    }
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Color color,
    required Rect rect,
    bool alignRight = false,
    bool alignBottom = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 12, height: 1.1),
      ),
      textAlign: alignRight ? TextAlign.right : TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    final dx = alignRight
        ? rect.right - painter.width
        : rect.left + (rect.width - painter.width) / 2;
    final dy = alignBottom
        ? rect.bottom - painter.height
        : rect.top + (rect.height - painter.height) / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  void _paintWrongFlash(Canvas canvas) {
    final row = wrongFlashRow;
    final col = wrongFlashCol;
    if (row == null || col == null || wrongFlashOpacity <= 0) return;
    canvas.drawRect(
      layout.cellRect(row, col),
      Paint()..color = palette.wrongFlash.withValues(alpha: wrongFlashOpacity),
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return session != oldDelegate.session ||
        palette != oldDelegate.palette ||
        wrongFlashRow != oldDelegate.wrongFlashRow ||
        wrongFlashCol != oldDelegate.wrongFlashCol ||
        wrongFlashOpacity != oldDelegate.wrongFlashOpacity;
  }
}
