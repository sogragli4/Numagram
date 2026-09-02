import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';

/// Result of [useHint]. [revealedRow]/[revealedCol] are `null` when no
/// hint could be applied (cap reached, session over, or the focused line
/// has nothing left to reveal) — callers use that to decide whether the
/// rewarded ad watch should actually be "spent".
class HintResult {
  const HintResult({
    required this.session,
    required this.revealedRow,
    required this.revealedCol,
  });

  final GameSession session;
  final int? revealedRow;
  final int? revealedCol;

  bool get hintApplied => revealedRow != null;
}

/// Reveals one correct, still-unknown cell in row [focusRow] — "the
/// currently focused line" in the Phase 4 spec, taken to mean the row the
/// player was last interacting with. Capped at
/// [GameLimits.maxHintsPerPuzzle] per puzzle.
///
/// Pure and synchronous: this only decides *what a hint would reveal*.
/// The caller is responsible for actually granting one (i.e. only calling
/// this after a rewarded ad watch completes).
HintResult useHint({required GameSession session, required int focusRow}) {
  if (session.isOver || session.hintsUsed >= GameLimits.maxHintsPerPuzzle) {
    return HintResult(session: session, revealedRow: null, revealedCol: null);
  }

  for (var c = 0; c < session.width; c++) {
    if (session.stateAt(focusRow, c) == CellState.unknown &&
        session.puzzle.solution.cellAt(focusRow, c)) {
      final cells = List<CellState>.of(session.cellStates);
      cells[focusRow * session.width + c] = CellState.filled;
      var updated = session.copyWith(
        cellStates: cells,
        hintsUsed: session.hintsUsed + 1,
      );
      if (updated.isFullySolved) updated = updated.copyWith(won: true);
      return HintResult(
        session: updated,
        revealedRow: focusRow,
        revealedCol: c,
      );
    }
  }

  // The focused row is already fully correct — nothing left to reveal.
  return HintResult(session: session, revealedRow: null, revealedCol: null);
}
