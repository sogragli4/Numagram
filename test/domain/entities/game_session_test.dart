import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';

// # .
// . #
Puzzle _testPuzzle() {
  final solution = PuzzleGrid.fromBools(2, 2, const [true, false, false, true]);
  return Puzzle(
    solution: solution,
    rowClues: const [
      LineClue([1]),
      LineClue([1]),
    ],
    columnClues: const [
      LineClue([1]),
      LineClue([1]),
    ],
    difficulty: Difficulty.easy,
    seed: 0,
    size: const GridSize(2, 2),
  );
}

void main() {
  group('isRowComplete / isColumnComplete', () {
    test('an all-unknown board has no complete lines', () {
      final session = GameSession.start(_testPuzzle());
      expect(session.isRowComplete(0), isFalse);
      expect(session.isColumnComplete(0), isFalse);
    });

    test('a row is complete once its solution cells are filled, '
        'regardless of marks elsewhere', () {
      final session = GameSession.start(_testPuzzle()).copyWith(
        cellStates: [
          CellState.filled,
          CellState.unknown,
          CellState.unknown,
          CellState.unknown,
        ],
      );
      expect(session.isRowComplete(0), isTrue);
      expect(session.isRowComplete(1), isFalse);
    });

    test('a wrongly filled cell prevents completion', () {
      final session = GameSession.start(_testPuzzle()).copyWith(
        cellStates: [
          CellState.filled,
          CellState.filled, // wrong: solution says this cell is empty
          CellState.unknown,
          CellState.unknown,
        ],
      );
      expect(session.isRowComplete(0), isFalse);
    });
  });
}
