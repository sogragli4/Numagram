import 'dart:ui';

/// Pixel geometry for the crossword grid — cell size and the mapping
/// between grid coordinates and canvas offsets. No clue gutters (unlike
/// Nonogram's `BoardLayout`): clue numbers print inside their starting
/// cell instead of a separate row/column margin.
class CrosswordLayout {
  const CrosswordLayout({
    required this.width,
    required this.height,
    required this.cellSize,
  });

  final int width;
  final int height;
  final double cellSize;

  Size get totalSize => Size(width * cellSize, height * cellSize);

  Rect cellRect(int row, int col) =>
      Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize);

  /// The `(row, col)` under [localPosition], or `null` if outside the
  /// grid entirely.
  (int, int)? cellAt(Offset localPosition) {
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();
    if (col < 0 || col >= width || row < 0 || row >= height) return null;
    return (row, col);
  }
}
