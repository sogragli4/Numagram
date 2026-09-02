import 'dart:ui';

import 'package:nonogram_daily/domain/entities/line_clue.dart';

/// Pixel geometry for the board: cell size, clue-gutter size, and the
/// mapping between grid coordinates and canvas offsets.
///
/// Shared by `BoardPainter` and the gesture handling in `BoardScreen` so
/// "where the board draws things" and "where taps land" can never drift
/// apart.
class BoardLayout {
  BoardLayout({
    required this.puzzleWidth,
    required this.puzzleHeight,
    required this.rowClues,
    required this.columnClues,
    this.cellSize = minTouchTargetSize,
  });

  /// Cells never render smaller than this, in logical pixels — the
  /// Phase 2 accessibility requirement ("minimum 44pt effective touch
  /// target after zoom"). Enforced by fixing this as the *unscaled* cell
  /// size and never letting `InteractiveViewer` zoom out past 1.0, rather
  /// than by clamping zoomed-out hit-test regions.
  static const double minTouchTargetSize = 44;

  final int puzzleWidth;
  final int puzzleHeight;
  final List<LineClue> rowClues;
  final List<LineClue> columnClues;
  final double cellSize;

  static const double _clueCharWidth = 11;
  static const double _clueLineHeight = 16;

  late final double clueGutterWidth = _gutterWidthFor(rowClues);
  late final double clueGutterHeight = _gutterHeightFor(columnClues);

  double _gutterWidthFor(List<LineClue> clues) {
    var maxChars = 1;
    for (final clue in clues) {
      final chars = clue.toString().length;
      if (chars > maxChars) maxChars = chars;
    }
    final estimated = maxChars * _clueCharWidth + 12;
    return estimated < cellSize ? cellSize : estimated;
  }

  double _gutterHeightFor(List<LineClue> clues) {
    var maxLines = 1;
    for (final clue in clues) {
      final lines = clue.runs.isEmpty ? 1 : clue.runs.length;
      if (lines > maxLines) maxLines = lines;
    }
    final estimated = maxLines * _clueLineHeight + 12;
    return estimated < cellSize ? cellSize : estimated;
  }

  double get gridWidth => puzzleWidth * cellSize;
  double get gridHeight => puzzleHeight * cellSize;

  Size get totalSize =>
      Size(clueGutterWidth + gridWidth, clueGutterHeight + gridHeight);

  Rect cellRect(int row, int col) => Rect.fromLTWH(
    clueGutterWidth + col * cellSize,
    clueGutterHeight + row * cellSize,
    cellSize,
    cellSize,
  );

  /// The `(row, col)` under [localPosition], or `null` if it's outside the
  /// grid (e.g. over a clue gutter).
  (int row, int col)? cellAt(Offset localPosition) {
    final x = localPosition.dx - clueGutterWidth;
    final y = localPosition.dy - clueGutterHeight;
    if (x < 0 || y < 0) return null;
    final col = (x / cellSize).floor();
    final row = (y / cellSize).floor();
    if (col < 0 || col >= puzzleWidth || row < 0 || row >= puzzleHeight) {
      return null;
    }
    return (row, col);
  }
}
