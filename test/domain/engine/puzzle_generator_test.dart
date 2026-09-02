import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/full_solver.dart';
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';

void main() {
  group('generatePuzzle', () {
    for (final size in [5, 10, 15, 20]) {
      test(
        'produces a Solved puzzle for ${size}x$size within the attempt budget',
        () {
          final puzzle = generatePuzzle(
            seed: 12345 + size,
            width: size,
            height: size,
          );

          expect(puzzle.size.width, size);
          expect(puzzle.size.height, size);
          expect(puzzle.rowClues, hasLength(size));
          expect(puzzle.columnClues, hasLength(size));

          // The puzzle is only valid if the clues alone (no peeking at the
          // solution) are enough for the full solver to reach Solved.
          final resolved = solveFull(
            width: size,
            height: size,
            rowClues: puzzle.rowClues,
            columnClues: puzzle.columnClues,
          );
          expect(resolved.outcome, SolverOutcome.solved);

          for (var r = 0; r < size; r++) {
            for (var c = 0; c < size; c++) {
              expect(
                resolved.cellAt(r, c),
                puzzle.solution.cellAt(r, c),
                reason:
                    'cell ($r,$c) mismatch between generated solution and '
                    'solver output',
              );
            }
          }
        },
      );
    }

    test('every row and column has at least one filled cell', () {
      final puzzle = generatePuzzle(seed: 999, width: 10, height: 10);
      for (var r = 0; r < 10; r++) {
        expect(
          puzzle.solution.rowCells(r),
          contains(true),
          reason: 'row $r is empty',
        );
      }
      for (var c = 0; c < 10; c++) {
        expect(
          puzzle.solution.columnCells(c),
          contains(true),
          reason: 'column $c is empty',
        );
      }
    });

    test('is deterministic for a fixed seed and size', () {
      final a = generatePuzzle(seed: 42, width: 8, height: 8);
      final b = generatePuzzle(seed: 42, width: 8, height: 8);
      expect(a.solution, equals(b.solution));
      expect(a.difficulty, equals(b.difficulty));
    });

    test('different seeds usually produce different puzzles', () {
      final a = generatePuzzle(seed: 1, width: 8, height: 8);
      final b = generatePuzzle(seed: 2, width: 8, height: 8);
      expect(a.solution, isNot(equals(b.solution)));
    });
  });
}
