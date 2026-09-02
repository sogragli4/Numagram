import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';

/// A record of one solved puzzle, as persisted by `StreakRepository`.
///
/// [date] is the calendar date of the daily/archive puzzle this completed
/// (`null` for a free-play session, which never counts toward the streak).
class PuzzleCompletion {
  const PuzzleCompletion({
    required this.date,
    required this.size,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.mistakeCount,
    required this.completedAt,
  });

  final DateTime? date;
  final GridSize size;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int mistakeCount;
  final DateTime completedAt;

  bool get isDailyPuzzle => date != null;
  bool get isPerfect => mistakeCount == 0;
}
