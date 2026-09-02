import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';

void main() {
  group('PuzzleGrid', () {
    test('empty grid has no filled cells', () {
      final grid = PuzzleGrid.empty(3, 3);
      expect(grid.filledCount, 0);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(grid.cellAt(r, c), isFalse);
        }
      }
    });

    test('fromBools round-trips cell values in row-major order', () {
      // . # .
      // # # #
      final grid = PuzzleGrid.fromBools(3, 2, const [
        false,
        true,
        false,
        true,
        true,
        true,
      ]);

      expect(grid.cellAt(0, 0), isFalse);
      expect(grid.cellAt(0, 1), isTrue);
      expect(grid.cellAt(0, 2), isFalse);
      expect(grid.cellAt(1, 0), isTrue);
      expect(grid.cellAt(1, 1), isTrue);
      expect(grid.cellAt(1, 2), isTrue);
      expect(grid.filledCount, 4);
    });

    test('rowCells and columnCells extract the right slices', () {
      final grid = PuzzleGrid.fromBools(3, 2, const [
        false,
        true,
        false,
        true,
        true,
        true,
      ]);

      expect(grid.rowCells(0), [false, true, false]);
      expect(grid.rowCells(1), [true, true, true]);
      expect(grid.columnCells(1), [true, true]);
    });

    test('rejects a cell list of the wrong length', () {
      expect(
        () => PuzzleGrid.fromBools(3, 2, const [true, false]),
        throwsArgumentError,
      );
    });

    test('rejects non-positive dimensions', () {
      expect(() => PuzzleGrid.empty(0, 5), throwsArgumentError);
      expect(() => PuzzleGrid.empty(5, -1), throwsArgumentError);
    });

    test('out-of-range cell access throws', () {
      final grid = PuzzleGrid.empty(3, 3);
      expect(() => grid.cellAt(3, 0), throwsRangeError);
      expect(() => grid.cellAt(0, 3), throwsRangeError);
    });

    test('value equality ignores identity', () {
      final a = PuzzleGrid.fromBools(2, 2, const [true, false, false, true]);
      final b = PuzzleGrid.fromBools(2, 2, const [true, false, false, true]);
      final c = PuzzleGrid.fromBools(2, 2, const [true, true, false, true]);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('handles grids larger than one bitset word (32 cells)', () {
      // 7 x 6 = 42 cells, spans two 32-bit words.
      const width = 7;
      const height = 6;
      final cells = List<bool>.generate(width * height, (i) => i.isEven);
      final grid = PuzzleGrid.fromBools(width, height, cells);

      for (var i = 0; i < cells.length; i++) {
        final r = i ~/ width;
        final c = i % width;
        expect(grid.cellAt(r, c), cells[i], reason: 'cell $i ($r,$c)');
      }
      expect(grid.filledCount, cells.where((b) => b).length);
    });
  });
}
