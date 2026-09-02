import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';

/// Result of [applyMove]: the updated session, plus enough detail for the
/// UI to react to *this specific* move (flash a cell red, play a haptic).
class MoveResult {
  const MoveResult({
    required this.session,
    required this.wasWrongFill,
    required this.row,
    required this.col,
  });

  final GameSession session;

  /// `true` if this move was a fill attempt on a cell that isn't part of
  /// the solution — the session's heart count already reflects the
  /// penalty; this flag is just so the UI knows to flash cell (row, col).
  final bool wasWrongFill;
  final int row;
  final int col;
}

/// Applies one player action to [session] at `(row, col)` and returns the
/// result. Pure and synchronous — no Flutter dependency.
///
/// [intent] must be [CellState.filled] (the player is asserting "this cell
/// is part of the solution") or [CellState.marked] (asserting "this cell
/// is empty"); [CellState.unknown] is not a valid intent.
///
/// Rules:
/// - Marking is never penalised: unknown <-> marked toggles freely, and
///   marking a filled cell is a no-op (undo the fill instead).
/// - Filling an already-filled cell undoes it (back to unknown), free.
/// - Filling a cell that matches the solution fills it. Filling a cell
///   that doesn't costs one heart and the cell stays/reverts to unknown
///   (a wrong guess is never left visibly "filled").
/// - No moves are accepted once the session [GameSession.isOver].
/// - If [autoMark] is true (the default) and this move completes a row or
///   column (every solution-filled cell in it is now filled), every
///   remaining unknown cell in that line is auto-marked.
MoveResult applyMove({
  required GameSession session,
  required int row,
  required int col,
  required CellState intent,
  bool autoMark = true,
}) {
  assert(
    intent == CellState.filled || intent == CellState.marked,
    'intent must be filled or marked, not $intent',
  );

  if (session.isOver) {
    return MoveResult(
      session: session,
      wasWrongFill: false,
      row: row,
      col: col,
    );
  }

  final width = session.width;
  final height = session.height;
  final cells = List<CellState>.of(session.cellStates);
  final current = cells[row * width + col];

  var hearts = session.heartsRemaining;
  var mistakes = session.mistakeCount;
  var wrong = false;

  if (intent == CellState.marked) {
    if (current == CellState.marked) {
      cells[row * width + col] = CellState.unknown;
    } else if (current == CellState.unknown) {
      cells[row * width + col] = CellState.marked;
    }
    // A filled cell is left untouched: clear the fill first, via a fill
    // intent, rather than mark mode silently overwriting it.
  } else {
    if (current == CellState.filled) {
      cells[row * width + col] = CellState.unknown;
    } else if (session.puzzle.solution.cellAt(row, col)) {
      cells[row * width + col] = CellState.filled;
    } else {
      wrong = true;
      hearts -= 1;
      mistakes += 1;
      cells[row * width + col] = CellState.unknown;
    }
  }

  // A cheap probe: wraps the working `cells` list without copying it, so
  // GameSession's own completion checks can be reused here instead of
  // duplicating that logic.
  var probe = session.copyWith(cellStates: cells);

  if (autoMark) {
    if (probe.isRowComplete(row)) {
      for (var c = 0; c < width; c++) {
        final idx = row * width + c;
        if (cells[idx] == CellState.unknown) cells[idx] = CellState.marked;
      }
    }
    if (probe.isColumnComplete(col)) {
      for (var r = 0; r < height; r++) {
        final idx = r * width + col;
        if (cells[idx] == CellState.unknown) cells[idx] = CellState.marked;
      }
    }
    probe = session.copyWith(cellStates: cells);
  }

  final updated = probe.copyWith(
    heartsRemaining: hearts,
    mistakeCount: mistakes,
    won: probe.isFullySolved,
  );
  return MoveResult(session: updated, wasWrongFill: wrong, row: row, col: col);
}
