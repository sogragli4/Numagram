import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';
import 'package:nonogram_daily/domain/usecases/validate_move.dart';

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
  group('GameSession.start', () {
    test('begins with every cell unknown and default hearts', () {
      final session = GameSession.start(_testPuzzle());
      expect(session.cellStates, everyElement(CellState.unknown));
      expect(session.heartsRemaining, 3);
      expect(session.mistakeCount, 0);
      expect(session.won, isFalse);
      expect(session.isOver, isFalse);
    });

    test('accepts a custom starting heart count', () {
      final session = GameSession.start(_testPuzzle(), startingHearts: 1);
      expect(session.heartsRemaining, 1);
    });
  });

  group('applyMove: filling', () {
    test('filling a correct cell fills it, no heart lost', () {
      final session = GameSession.start(_testPuzzle());
      final result = applyMove(
        session: session,
        row: 0,
        col: 0,
        intent: CellState.filled,
      );
      expect(result.wasWrongFill, isFalse);
      expect(result.session.stateAt(0, 0), CellState.filled);
      expect(result.session.heartsRemaining, 3);
      expect(result.session.mistakeCount, 0);
    });

    test('filling a wrong cell costs a heart and reverts to unknown', () {
      final session = GameSession.start(_testPuzzle());
      final result = applyMove(
        session: session,
        row: 0,
        col: 1, // solution is empty here
        intent: CellState.filled,
      );
      expect(result.wasWrongFill, isTrue);
      expect(result.session.stateAt(0, 1), CellState.unknown);
      expect(result.session.heartsRemaining, 2);
      expect(result.session.mistakeCount, 1);
    });

    test('filling an already-filled cell undoes it for free', () {
      final session = GameSession.start(_testPuzzle());
      final filled = applyMove(
        session: session,
        row: 0,
        col: 0,
        intent: CellState.filled,
      ).session;
      final undone = applyMove(
        session: filled,
        row: 0,
        col: 0,
        intent: CellState.filled,
      );
      expect(undone.session.stateAt(0, 0), CellState.unknown);
      expect(undone.session.heartsRemaining, filled.heartsRemaining);
      expect(undone.wasWrongFill, isFalse);
    });

    test('filling over a mark overwrites it when correct', () {
      final session = GameSession.start(_testPuzzle());
      final marked = applyMove(
        session: session,
        row: 0,
        col: 0,
        intent: CellState.marked,
      ).session;
      expect(marked.stateAt(0, 0), CellState.marked);

      final filled = applyMove(
        session: marked,
        row: 0,
        col: 0,
        intent: CellState.filled,
      );
      expect(filled.session.stateAt(0, 0), CellState.filled);
    });
  });

  group('applyMove: marking', () {
    test('marking an unknown cell marks it, marking again clears it', () {
      final session = GameSession.start(_testPuzzle());
      final marked = applyMove(
        session: session,
        row: 1,
        col: 0,
        intent: CellState.marked,
      );
      expect(marked.session.stateAt(1, 0), CellState.marked);
      expect(marked.wasWrongFill, isFalse);
      expect(marked.session.heartsRemaining, 3);

      final unmarked = applyMove(
        session: marked.session,
        row: 1,
        col: 0,
        intent: CellState.marked,
      );
      expect(unmarked.session.stateAt(1, 0), CellState.unknown);
    });

    test('marking a filled cell is a no-op', () {
      final session = GameSession.start(_testPuzzle());
      final filled = applyMove(
        session: session,
        row: 0,
        col: 0,
        intent: CellState.filled,
      ).session;
      final result = applyMove(
        session: filled,
        row: 0,
        col: 0,
        intent: CellState.marked,
      );
      expect(result.session.stateAt(0, 0), CellState.filled);
    });

    test('marking is never penalised, even when the cell should be filled', () {
      final session = GameSession.start(_testPuzzle());
      final result = applyMove(
        session: session,
        row: 0,
        col: 0, // solution says this should be filled
        intent: CellState.marked,
      );
      expect(result.session.heartsRemaining, 3);
      expect(result.session.mistakeCount, 0);
    });
  });

  group('auto-mark', () {
    test('completing a row marks its remaining unknown cells', () {
      // Row 1 clue is [1]: filling (1,1) alone completes row 1.
      final session = GameSession.start(_testPuzzle());
      final result = applyMove(
        session: session,
        row: 1,
        col: 1,
        intent: CellState.filled,
      );
      expect(result.session.stateAt(1, 0), CellState.marked);
      expect(result.session.stateAt(1, 2), CellState.marked);
    });

    test('can be disabled', () {
      final session = GameSession.start(_testPuzzle());
      final result = applyMove(
        session: session,
        row: 1,
        col: 1,
        intent: CellState.filled,
        autoMark: false,
      );
      expect(result.session.stateAt(1, 0), CellState.unknown);
      expect(result.session.stateAt(1, 2), CellState.unknown);
    });

    test('completing a column marks its remaining unknown cells', () {
      final session = GameSession.start(_testPuzzle());
      final result = applyMove(
        session: session,
        row: 1,
        col: 1,
        intent: CellState.filled,
      );
      expect(result.session.stateAt(0, 1), CellState.marked);
      expect(result.session.stateAt(2, 1), CellState.marked);
    });
  });

  group('win detection', () {
    test('is won only once every solution cell is correctly filled', () {
      var session = GameSession.start(_testPuzzle());
      const filledCells = [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)];
      for (final (i, (row, col)) in filledCells.indexed) {
        final result = applyMove(
          session: session,
          row: row,
          col: col,
          intent: CellState.filled,
        );
        session = result.session;
        final isLast = i == filledCells.length - 1;
        expect(session.won, isLast);
      }
    });
  });

  group('game over', () {
    test('running out of hearts stops accepting moves', () {
      var session = GameSession.start(_testPuzzle(), startingHearts: 1);
      final wrong = applyMove(
        session: session,
        row: 0,
        col: 1,
        intent: CellState.filled,
      );
      session = wrong.session;
      expect(session.outOfHearts, isTrue);
      expect(session.isOver, isTrue);

      final afterGameOver = applyMove(
        session: session,
        row: 0,
        col: 0,
        intent: CellState.filled,
      );
      expect(afterGameOver.session.stateAt(0, 0), CellState.unknown);
      expect(afterGameOver.wasWrongFill, isFalse);
    });

    test('winning stops accepting further moves', () {
      var session = GameSession.start(_testPuzzle());
      for (final (row, col) in const [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)]) {
        session = applyMove(
          session: session,
          row: row,
          col: col,
          intent: CellState.filled,
        ).session;
      }
      expect(session.won, isTrue);
      // (0, 1) was already auto-marked when row 0 completed mid-sequence.
      final stateBeforeNoOpMove = session.stateAt(0, 1);

      final afterWin = applyMove(
        session: session,
        row: 0,
        col: 1,
        intent: CellState.marked,
      );
      expect(afterWin.session.stateAt(0, 1), stateBeforeNoOpMove);
      expect(afterWin.session.heartsRemaining, session.heartsRemaining);
    });
  });
}
