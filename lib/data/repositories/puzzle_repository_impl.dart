import 'package:nonogram_daily/data/datasources/puzzle_generator_data_source.dart';
import 'package:nonogram_daily/domain/engine/stable_hash.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/repositories/puzzle_repository.dart';
import 'package:nonogram_daily/domain/usecases/daily_puzzle_plan.dart';

class PuzzleRepositoryImpl implements PuzzleRepository {
  const PuzzleRepositoryImpl(this._generator);

  final PuzzleGeneratorDataSource _generator;

  @override
  Future<Puzzle> getDailyPuzzle(DateTime date) {
    final size = dailySizeForDate(date);
    return _generator.generate(
      seed: seedForDate(date),
      width: size.width,
      height: size.height,
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
