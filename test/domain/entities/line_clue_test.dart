import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';

void main() {
  group('LineClue.fromCells', () {
    test('all-empty line has no runs', () {
      expect(LineClue.fromCells(const [false, false, false]).runs, isEmpty);
    });

    test('fully filled line is a single run', () {
      expect(LineClue.fromCells(const [true, true, true]).runs, [3]);
    });

    test('separates runs by gaps', () {
      // # . # # . #
      expect(
        LineClue.fromCells(const [true, false, true, true, false, true]).runs,
        [1, 2, 1],
      );
    });

    test('trailing run is captured', () {
      expect(LineClue.fromCells(const [false, true, true]).runs, [2]);
    });
  });

  group('LineClue value semantics', () {
    test('equal run lists are equal', () {
      expect(const LineClue([1, 2]), equals(const LineClue([1, 2])));
      expect(
        const LineClue([1, 2]).hashCode,
        equals(const LineClue([1, 2]).hashCode),
      );
    });

    test('different run lists are not equal', () {
      expect(const LineClue([1, 2]), isNot(equals(const LineClue([2, 1]))));
      expect(const LineClue([1, 2]), isNot(equals(const LineClue([1]))));
    });

    test('minimumLineLength accounts for mandatory gaps', () {
      expect(const LineClue([]).minimumLineLength, 0);
      expect(const LineClue([3]).minimumLineLength, 3);
      expect(const LineClue([1, 2, 1]).minimumLineLength, 1 + 2 + 1 + 2);
    });
  });
}
