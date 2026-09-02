import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/full_solver.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/domain/usecases/tutorial_script.dart';
import 'package:nonogram_daily/domain/usecases/validate_move.dart';

void main() {
  group('buildTutorialPuzzle', () {
    test('is solvable without guessing, from its clues alone', () {
      final puzzle = buildTutorialPuzzle();

      final result = solveFull(
        width: puzzle.size.width,
        height: puzzle.size.height,
        rowClues: puzzle.rowClues,
        columnClues: puzzle.columnClues,
      );

      expect(result.outcome, SolverOutcome.solved);
      for (var r = 0; r < puzzle.size.height; r++) {
        for (var c = 0; c < puzzle.size.width; c++) {
          expect(
            result.cellAt(r, c),
            puzzle.solution.cellAt(r, c),
            reason: 'solver disagreed with the authored solution at ($r, $c)',
          );
        }
      }
    });
  });

  group('buildTutorialScript', () {
    test('every target cell is actually a solution-filled cell', () {
      final puzzle = buildTutorialPuzzle();
      final script = buildTutorialScript();

      for (final step in script) {
        for (final (row, col) in step.targetCells) {
          expect(
            step.requiredIntent,
            CellState.filled,
            reason: 'this script only ever asks the player to fill cells',
          );
          expect(
            puzzle.solution.cellAt(row, col),
            isTrue,
            reason: 'target ($row, $col) is not part of the solution',
          );
        }
      }
    });

    test('playing every target through applyMove — with its real auto-mark '
        'behavior — fully solves the puzzle', () {
      final puzzle = buildTutorialPuzzle();
      final script = buildTutorialScript();
      var session = GameSession.start(puzzle);

      for (final step in script) {
        for (final (row, col) in step.targetCells) {
          final result = applyMove(
            session: session,
            row: row,
            col: col,
            intent: step.requiredIntent ?? CellState.filled,
          );
          session = result.session;
        }
      }

      expect(
        session.won,
        isTrue,
        reason:
            'the scripted taps should fully solve the tutorial puzzle, '
            "relying on the real engine's auto-mark behavior for the "
            'cells the script never explicitly targets',
      );
    });
  });
}
