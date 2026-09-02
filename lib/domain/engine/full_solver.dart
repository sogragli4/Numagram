import 'package:nonogram_daily/domain/engine/line_solver.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';

enum SolverOutcome { solved, stuck, contradiction }

/// Outcome of running [solveFull], plus the stats [difficulty scoring][1]
/// needs.
///
/// [1]: package:nonogram_daily/domain/engine/difficulty_scorer.dart
class SolverRunResult {
  const SolverRunResult({
    required this.outcome,
    required this.board,
    required this.width,
    required this.height,
    required this.passCount,
    required this.firstPassDeducedFraction,
  });

  final SolverOutcome outcome;

  /// Row-major final board state, length `width * height`.
  final List<CellState> board;
  final int width;
  final int height;

  /// Number of full row+column sweeps performed (including the final,
  /// no-progress sweep that ended the loop).
  final int passCount;

  /// Fraction of cells deduced in the very first sweep — a proxy for how
  /// "obvious" the puzzle is before any chained reasoning.
  final double firstPassDeducedFraction;

  bool cellAt(int row, int col) => board[row * width + col] == CellState.filled;
}

/// Repeatedly solves every row then every column with [solveLine] until a
/// full pass deduces nothing new.
///
/// A puzzle is uniquely solvable, without guessing, exactly when this
/// returns [SolverOutcome.solved] — that single check is both the
/// uniqueness proof and the human-solvability proof; no separate check is
/// needed.
SolverRunResult solveFull({
  required int width,
  required int height,
  required List<LineClue> rowClues,
  required List<LineClue> columnClues,
}) {
  final board = List<CellState>.filled(width * height, CellState.unknown);
  var pass = 0;
  var firstPassDeducedFraction = 0.0;

  SolverRunResult contradictionResult() => SolverRunResult(
    outcome: SolverOutcome.contradiction,
    board: board,
    width: width,
    height: height,
    passCount: pass,
    firstPassDeducedFraction: firstPassDeducedFraction,
  );

  while (true) {
    pass++;
    var deducedThisPass = 0;

    for (var r = 0; r < height; r++) {
      final rowCells = List<CellState>.generate(
        width,
        (c) => board[r * width + c],
      );
      final result = solveLine(rowClues[r].runs, rowCells);
      if (result is LineContradiction) return contradictionResult();
      final newRow = (result as LineSolved).cells;
      for (var c = 0; c < width; c++) {
        final index = r * width + c;
        if (board[index] == CellState.unknown &&
            newRow[c] != CellState.unknown) {
          board[index] = newRow[c];
          deducedThisPass++;
        }
      }
    }

    for (var c = 0; c < width; c++) {
      final colCells = List<CellState>.generate(
        height,
        (r) => board[r * width + c],
      );
      final result = solveLine(columnClues[c].runs, colCells);
      if (result is LineContradiction) return contradictionResult();
      final newCol = (result as LineSolved).cells;
      for (var r = 0; r < height; r++) {
        final index = r * width + c;
        if (board[index] == CellState.unknown &&
            newCol[r] != CellState.unknown) {
          board[index] = newCol[r];
          deducedThisPass++;
        }
      }
    }

    if (pass == 1) {
      firstPassDeducedFraction = deducedThisPass / (width * height);
    }

    if (deducedThisPass == 0) break;
  }

  final solved = !board.contains(CellState.unknown);
  return SolverRunResult(
    outcome: solved ? SolverOutcome.solved : SolverOutcome.stuck,
    board: board,
    width: width,
    height: height,
    passCount: pass,
    firstPassDeducedFraction: firstPassDeducedFraction,
  );
}
