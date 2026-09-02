import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/repositories/puzzle_repository.dart';

/// Fetches (generating if needed) the daily puzzle for a given date —
/// today's puzzle on first open of the day, or any past date via the
/// archive. Thin orchestration only; all the real work is
/// `PuzzleRepository`'s.
class GenerateDailyPuzzle {
  const GenerateDailyPuzzle(this._repository);

  final PuzzleRepository _repository;

  Future<Puzzle> call(DateTime date) => _repository.getDailyPuzzle(date);
}
