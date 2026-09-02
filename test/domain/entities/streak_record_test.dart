import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

void main() {
  group('StreakRecord.compute', () {
    test('no completions at all', () {
      final streak = StreakRecord.compute(
        completedDates: {},
        today: _d(2026, 9, 10),
      );
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
    });

    test('completed today only', () {
      final streak = StreakRecord.compute(
        completedDates: {_d(2026, 9, 10)},
        today: _d(2026, 9, 10),
      );
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 1);
    });

    test('consecutive days ending today', () {
      final streak = StreakRecord.compute(
        completedDates: {_d(2026, 9, 8), _d(2026, 9, 9), _d(2026, 9, 10)},
        today: _d(2026, 9, 10),
      );
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('yesterday completed but today not yet — streak stays alive', () {
      final streak = StreakRecord.compute(
        completedDates: {_d(2026, 9, 8), _d(2026, 9, 9)},
        today: _d(2026, 9, 10),
      );
      expect(streak.currentStreak, 2);
    });

    test('a missed day (today and yesterday both empty) resets to 0', () {
      final streak = StreakRecord.compute(
        completedDates: {_d(2026, 9, 5), _d(2026, 9, 6)},
        today: _d(2026, 9, 10),
      );
      expect(streak.currentStreak, 0);
      // The old run is still reflected in the longest streak.
      expect(streak.longestStreak, 2);
    });

    test('longest streak can exceed the current one', () {
      final streak = StreakRecord.compute(
        completedDates: {
          _d(2026, 9, 1),
          _d(2026, 9, 2),
          _d(2026, 9, 3),
          _d(2026, 9, 4),
          // gap on the 5th
          _d(2026, 9, 6),
        },
        today: _d(2026, 9, 6),
      );
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 4);
    });

    test('time-of-day is ignored when normalizing dates', () {
      final streak = StreakRecord.compute(
        completedDates: {
          DateTime(2026, 9, 10, 23, 59),
          DateTime(2026, 9, 9, 0, 1),
        },
        today: DateTime(2026, 9, 10, 8),
      );
      expect(streak.currentStreak, 2);
      expect(streak.completedDates, {_d(2026, 9, 9), _d(2026, 9, 10)});
    });

    test('filling in a past date via the archive can repair the streak', () {
      // Missed the 5th, but backfilled it later via the archive.
      final streak = StreakRecord.compute(
        completedDates: {_d(2026, 9, 4), _d(2026, 9, 5), _d(2026, 9, 6)},
        today: _d(2026, 9, 6),
      );
      expect(streak.currentStreak, 3);
    });
  });
}
