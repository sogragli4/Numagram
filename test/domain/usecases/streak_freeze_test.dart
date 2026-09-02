import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/usecases/streak_freeze.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

void main() {
  group('shouldAutoFreezeYesterday', () {
    test('freezes yesterday when the day before it was an active streak', () {
      final result = shouldAutoFreezeYesterday(
        completedDates: {_d(2026, 9, 8)},
        frozenDates: {},
        today: _d(2026, 9, 10),
        freezesAvailable: 1,
      );
      expect(result, isTrue);
    });

    test('does nothing if yesterday was already completed', () {
      final result = shouldAutoFreezeYesterday(
        completedDates: {_d(2026, 9, 8), _d(2026, 9, 9)},
        frozenDates: {},
        today: _d(2026, 9, 10),
        freezesAvailable: 1,
      );
      expect(result, isFalse);
    });

    test('does nothing if yesterday was already frozen', () {
      final result = shouldAutoFreezeYesterday(
        completedDates: {_d(2026, 9, 8)},
        frozenDates: {_d(2026, 9, 9)},
        today: _d(2026, 9, 10),
        freezesAvailable: 1,
      );
      expect(result, isFalse);
    });

    test('does nothing without a freeze available', () {
      final result = shouldAutoFreezeYesterday(
        completedDates: {_d(2026, 9, 8)},
        frozenDates: {},
        today: _d(2026, 9, 10),
        freezesAvailable: 0,
      );
      expect(result, isFalse);
    });

    test('does nothing when there was no active streak going into the gap', () {
      final result = shouldAutoFreezeYesterday(
        completedDates: {},
        frozenDates: {},
        today: _d(2026, 9, 10),
        freezesAvailable: 1,
      );
      expect(result, isFalse);
    });

    test('does not bridge a two-day-old gap with a single freeze', () {
      // Neither the 7th nor the 8th (yesterday) was completed.
      final result = shouldAutoFreezeYesterday(
        completedDates: {_d(2026, 9, 6)},
        frozenDates: {},
        today: _d(2026, 9, 10),
        freezesAvailable: 1,
      );
      expect(result, isFalse);
    });

    test('a day-before-yesterday that was itself frozen still counts', () {
      final result = shouldAutoFreezeYesterday(
        completedDates: {_d(2026, 9, 7)},
        frozenDates: {_d(2026, 9, 8)},
        today: _d(2026, 9, 10),
        freezesAvailable: 1,
      );
      expect(result, isTrue);
    });
  });

  group('isNewMonthlyFreezeGrantDue', () {
    test('is due when never granted before', () {
      expect(
        isNewMonthlyFreezeGrantDue(
          todayMonthKey: '2026-09',
          lastGrantMonthKey: null,
        ),
        isTrue,
      );
    });

    test('is due once the month changes', () {
      expect(
        isNewMonthlyFreezeGrantDue(
          todayMonthKey: '2026-09',
          lastGrantMonthKey: '2026-08',
        ),
        isTrue,
      );
    });

    test('is not due again within the same month', () {
      expect(
        isNewMonthlyFreezeGrantDue(
          todayMonthKey: '2026-09',
          lastGrantMonthKey: '2026-09',
        ),
        isFalse,
      );
    });
  });
}
