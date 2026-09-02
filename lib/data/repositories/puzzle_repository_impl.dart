import 'package:nonogram_daily/data/datasources/puzzle_generator_data_source.dart';
import 'package:nonogram_daily/domain/engine/stable_hash.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/repositories/puzzle_repository.dart';

/// The daily puzzle is always this size for v1 — chosen because it's the
/// size the Phase 1 difficulty scorer was calibrated against ("10x10
/// lands in medium"). Varying size by day/streak milestone is a
/// reasonable Phase 5 progression idea, not decided here.
const dailyPuzzleWidth = 10;
const dailyPuzzleHeight = 10;

class PuzzleRepositoryImpl implements PuzzleRepository {
  const PuzzleRepositoryImpl(this._generator);

  final PuzzleGeneratorDataSource _generator;

  @override
  Future<Puzzle> getDailyPuzzle(DateTime date) {
    return _generator.generate(
      seed: seedForDate(date),
      width: dailyPuzzleWidth,
      height: dailyPuzzleHeight,
    );
  }

  @override
  Future<Puzzle> getFreePlayPuzzle({
    required int width,
    required int height,
    int? seed,
  }) {
    return _generator.generate(
      seed: seed ?? DateTime.now().microsecondsSinceEpoch,
      width: width,
      height: height,
    );
  }
}
