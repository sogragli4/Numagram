import 'package:nonogram_daily/domain/entities/puzzle.dart';

/// Source of puzzles. Never caches solved grids — every puzzle (daily,
/// archive, or free play) is regenerated on demand from its seed, so the
/// archive costs zero storage (Phase 3 spec).
abstract class PuzzleRepository {
  /// The canonical daily puzzle for [date], deterministic from the date
  /// alone. Playing a past date's daily puzzle *is* the archive feature —
  /// there's no separate "archive puzzle".
  Future<Puzzle> getDailyPuzzle(DateTime date);

  /// A free-play puzzle at the requested size. Random (not date-seeded)
  /// unless [seed] is supplied, e.g. for testing.
  Future<Puzzle> getFreePlayPuzzle({
    required int width,
    required int height,
    int? seed,
  });
}
