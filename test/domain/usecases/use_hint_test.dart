import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';
import 'package:nonogram_daily/domain/usecases/use_hint.dart';

// # . #
// . # .
// # . #
Puzzle _testPuzzle() {
  final solution = PuzzleGrid.fromBools(3, 3, const [
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
  ]);
  return Puzzle(
    solution: solution,
    rowClues: const [
      LineClue([1, 1]),
      LineClue([1]),
      LineClue([1, 1]),
    ],
    columnClues: const [
      LineClue([1, 1]),
      LineClue([1]),
      LineClue([1, 1]),
    ],
    difficulty: Difficulty.easy,
    seed: 0,
    size: const GridSize(3, 3),
  );
}

void main() {
  group('useHint', () {
    test('reveals a correct unknown cell in the focused row', () {
      final session = GameSession.start(_testPuzzle());
      final result = useHint(session: session, focusRow: 0);

      expect(result.hintApplied, isTrue);
      expect(result.revealedRow, 0);
      expect([0, 2], contains(result.revealedCol));
      expect(
        result.session.stateAt(result.revealedRow!, result.revealedCol!),
        CellState.filled,
      );
      expect(result.session.hintsUsed, 1);
    });

    test('never reveals a cell that should stay empty', () {
      final session = GameSession.start(_testPuzzle());
      final result = useHint(session: session, focusRow: 0);
      // Row 0 is # . # — the revealed cell must be one of the two filled
      // ones, never the middle empty cell.
      expect(result.revealedCol, isNot(1));
    });

    test('does nothing once the focused row is already fully correct', () {
      final session = GameSession.start(_testPuzzle()).copyWith(
        cellStates: [
          CellState.filled,
          CellState.unknown,
          CellState.filled,
          CellState.unknown,
          CellState.unknown,
          CellState.unknown,
          CellState.unknown,
          CellState.unknown,
          CellState.unknown,
        ],
      );
      final result = useHint(session: session, focusRow: 0);
      expect(result.hintApplied, isFalse);
      expect(result.session, same(session));
    });

    test('is capped at GameLimits.maxHintsPerPuzzle', () {
      var session = GameSession.start(_testPuzzle());
      // Row 2's two fillable cells, then one of row 0's, reaches the cap
      // of 3 (GameLimits.maxHintsPerPuzzle) exactly.
      session = useHint(session: session, focusRow: 2).session;
      session = useHint(session: session, focusRow: 2).session;
      session = useHint(session: session, focusRow: 0).session;
      expect(session.hintsUsed, 3);

      final fourth = useHint(session: session, focusRow: 0);
      expect(fourth.hintApplied, isFalse);
      expect(fourth.session.hintsUsed, 3);
    });

    test('completing the puzzle via a hint marks it won', () {
      // Fill everything except one cell by hand, then let the hint finish it.
      final session = GameSession.start(_testPuzzle()).copyWith(
        cellStates: [
          CellState.filled,
          CellState.marked,
          CellState.unknown,
          CellState.marked,
          CellState.filled,
          CellState.marked,
          CellState.filled,
          CellState.marked,
          CellState.filled,
        ],
      );
      final result = useHint(session: session, focusRow: 0);
      expect(result.hintApplied, isTrue);
      expect(result.session.won, isTrue);
    });

    test('does nothing once the session is already over', () {
      final wonSession = GameSession.start(_testPuzzle()).copyWith(won: true);
      final result = useHint(session: wonSession, focusRow: 0);
      expect(result.hintApplied, isFalse);
    });
  });
}
