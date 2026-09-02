import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/usecases/daily_puzzle_plan.dart';

void main() {
  group('dailySizeForDate', () {
    test('a Saturday is the larger weekend-challenge size', () {
      // 2026-09-05 is a Saturday.
      expect(dailySizeForDate(DateTime(2026, 9, 5)), const GridSize(15, 15));
    });

    test('a Sunday is the smaller light-day size', () {
      // 2026-09-06 is a Sunday.
      expect(dailySizeForDate(DateTime(2026, 9, 6)), const GridSize(5, 5));
    });

    test('every weekday is the standard size', () {
      // 2026-08-31 (Mon) .. 2026-09-04 (Fri).
      for (var day = 31; day <= 35; day++) {
        final date = DateTime(2026, 8, day);
        expect(
          dailySizeForDate(date),
          const GridSize(dailyPuzzleWidth, dailyPuzzleHeight),
          reason:
              '$date (weekday ${date.weekday}) should be the standard '
              'size',
        );
      }
    });

    test('ignores time-of-day, matching seedForDate', () {
      final atMidnight = dailySizeForDate(DateTime(2026, 9, 5));
      final atNight = dailySizeForDate(DateTime(2026, 9, 5, 23, 59, 59));
      expect(atMidnight, atNight);
    });

    test('pinned: known dates map to their expected size, so a future change '
        "here can't silently resize a real player's daily puzzle", () {
      const pinned = {
        '2026-09-01 (Tue)': (2026, 9, 1, GridSize(10, 10)),
        '2026-09-05 (Sat)': (2026, 9, 5, GridSize(15, 15)),
        '2026-09-06 (Sun)': (2026, 9, 6, GridSize(5, 5)),
      };

      for (final entry in pinned.entries) {
        final (year, month, day, expected) = entry.value;
        expect(
          dailySizeForDate(DateTime(year, month, day)),
          expected,
          reason: entry.key,
        );
      }
    });
  });
}
