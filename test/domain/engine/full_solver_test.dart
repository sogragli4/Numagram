import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/full_solver.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';

void main() {
  group('solveFull', () {
    test('solves a 5x5 puzzle that requires row-then-column propagation', () {
      // # # # # #
      // # . . . #
      // # . # . #
      // # . . . #
      // # # # # #
      const rowClues = [
        LineClue([5]),
        LineClue([1, 1]),
        LineClue([1, 1, 1]),
        LineClue([1, 1]),
        LineClue([5]),
      ];
      const columnClues = [
        LineClue([5]),
        LineClue([1, 1]),
        LineClue([1, 1, 1]),
        LineClue([1, 1]),
        LineClue([5]),
      ];

      final result = solveFull(
        width: 5,
        height: 5,
        rowClues: rowClues,
        columnClues: columnClues,
      );

      expect(result.outcome, SolverOutcome.solved);
      expect(result.board, everyElement(isNot(CellState.unknown)));

      const expected = [
        true,
        true,
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        true,
        true,
        false,
        true,
        false,
        true,
        true,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        true,
      ];
      for (var i = 0; i < expected.length; i++) {
        expect(result.cellAt(i ~/ 5, i % 5), expected[i], reason: 'cell $i');
      }

      // Row1/row3 are only resolvable once column info is available; a
      // pass is one full row sweep *followed by* one full column sweep,
      // so this puzzle happens to fully resolve within pass 1 — but only
      // because the column sweep runs after the rows, not because every
      // cell was obvious on its own.
      expect(result.firstPassDeducedFraction, greaterThan(0));
      expect(result.passCount, greaterThanOrEqualTo(1));
    });

    test('reports Stuck when the puzzle needs guessing', () {
      // A 2x2 grid with a single diagonal cell per row/column has two
      // valid solutions (the two diagonals) — line-only propagation can
      // never disambiguate them.
      const rowClues = [
        LineClue([1]),
        LineClue([1]),
      ];
      const columnClues = [
        LineClue([1]),
        LineClue([1]),
      ];

      final result = solveFull(
        width: 2,
        height: 2,
        rowClues: rowClues,
        columnClues: columnClues,
      );

      expect(result.outcome, SolverOutcome.stuck);
      expect(result.board, everyElement(CellState.unknown));
    });

    test('reports Contradiction when row and column clues disagree', () {
      // A single cell that the row clue says must be filled and the
      // column clue says must be empty.
      final result = solveFull(
        width: 1,
        height: 1,
        rowClues: const [
          LineClue([1]),
        ],
        columnClues: const [LineClue([])],
      );

      expect(result.outcome, SolverOutcome.contradiction);
    });

    test('terminates on 1000 random small puzzles without throwing', () {
      // Regression guard for infinite loops / non-termination — not a
      // solvability claim, just that solveFull always returns.
      final rng = List.generate(1000, (i) => i);
      for (final seed in rng) {
        final width = 3 + (seed % 6);
        final height = 3 + ((seed ~/ 6) % 6);
        final cells = List<bool>.generate(
          width * height,
          (i) => (i * 2654435761 + seed) % 5 < 3,
        );
        final rowClues = [
          for (var r = 0; r < height; r++)
            LineClue.fromCells(cells.sublist(r * width, r * width + width)),
        ];
        final columnClues = [
          for (var c = 0; c < width; c++)
            LineClue.fromCells([
              for (var r = 0; r < height; r++) cells[r * width + c],
            ]),
        ];

        expect(
          () => solveFull(
            width: width,
            height: height,
            rowClues: rowClues,
            columnClues: columnClues,
          ),
          returnsNormally,
        );
      }
    });
  });
}
