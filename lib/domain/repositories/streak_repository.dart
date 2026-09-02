import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';
import 'package:nonogram_daily/domain/entities/statistics.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';

/// Persists completed puzzles and derives streak/statistics from them.
/// Recording is idempotent per calendar date: completing an already-solved
/// date's daily puzzle again does not create a second record or affect
/// statistics twice.
abstract class StreakRepository {
  Future<void> recordCompletion(PuzzleCompletion completion);

  Future<StreakRecord> getStreak({required DateTime today});

  Future<Statistics> getStatistics();

  /// Every calendar date with a recorded daily-puzzle completion, for
  /// driving the calendar screen.
  Future<Set<DateTime>> getCompletedDates();
}
