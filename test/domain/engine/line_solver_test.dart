import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/line_solver.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';

const u = CellState.unknown;
const f = CellState.filled;
const m = CellState.marked;

List<CellState> _solved(List<int> clues, List<CellState> known) {
  final result = solveLine(clues, known);
  expect(
    result,
    isA<LineSolved>(),
    reason: 'expected a solved result, got $result',
  );
  return (result as LineSolved).cells;
}

void main() {
  group('solveLine edge cases', () {
    test('empty clue marks every unknown cell empty', () {
      expect(_solved([], [u, u, u]), [m, m, m]);
    });

    test('empty clue on an already-empty line changes nothing', () {
      expect(_solved([], [m, m, m]), [m, m, m]);
    });

    test('a single run spanning the whole line fills every cell', () {
      expect(_solved([3], [u, u, u]), [f, f, f]);
    });

    test('exact-fit clue with mandatory gaps has one placement', () {
      // [1, 1] in a length-3 line only fits as # . #
      expect(_solved([1, 1], [u, u, u]), [f, m, f]);
    });

    test(
      'overlap deduction: run longer than half the line forces its middle',
      () {
        // length 5, run 3: leftmost start 0 (covers 0-2), rightmost start 2
        // (covers 2-4) -> only cell 2 is filled in every placement.
        expect(_solved([3], [u, u, u, u, u]), [u, u, f, u, u]);
      },
    );

    test('overlap deduction with a wider gap', () {
      // length 6, run 4: leftmost start 0 (0-3), rightmost start 2 (2-5)
      // -> cells 2-3 filled in every placement, 0/1/4/5 stay unknown.
      expect(_solved([4], [u, u, u, u, u, u]), [u, u, f, f, u, u]);
    });

    test('a known marked cell rules out placements that would cover it', () {
      // length 5, run 3, cell 0 marked -> run must start at 1 or 2.
      // leftmost covers 1-3, rightmost covers 2-4 -> cells 2-3 forced.
      expect(_solved([3], [m, u, u, u, u]), [m, u, f, f, u]);
    });

    test(
      'a fully specified line consistent with its clue is returned unchanged',
      () {
        expect(_solved([1, 1], [f, m, f]), [f, m, f]);
      },
    );

    test('overlap deduction across two runs', () {
      // length 5, clues [2, 1]: slack is 1, so run 1 (length 2) can only
      // start at 0 or 1 — every valid placement (TTFTF, TTFFT, FTTFT)
      // fills index 1, so it's forced even though nothing was known.
      expect(_solved([2, 1], [u, u, u, u, u]), [u, f, u, u, u]);
    });
  });

  group('solveLine contradictions', () {
    test('a run that cannot fit around a marked cell is a contradiction', () {
      // length 3, run 3 must cover the whole line, but index 1 is marked.
      expect(solveLine([3], [u, m, u]), isA<LineContradiction>());
    });

    test('two adjacent filled cells cannot be covered by a length-1 run', () {
      expect(solveLine([1], [f, f, u]), isA<LineContradiction>());
    });

    test('more filled cells than any run can account for', () {
      // length 4, single run of 2, but cells 0 and 3 are both filled and
      // cannot both belong to one run of length 2.
      expect(solveLine([2], [f, u, u, f]), isA<LineContradiction>());
    });
  });
}
