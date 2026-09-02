import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';
import 'package:nonogram_daily/domain/repositories/streak_repository.dart';

/// Records a solved puzzle and returns the streak as it stands afterward.
class UpdateStreak {
  const UpdateStreak(this._repository);

  final StreakRepository _repository;

  Future<StreakRecord> call({
    required PuzzleCompletion completion,
    required DateTime today,
  }) async {
    await _repository.recordCompletion(completion);
    return _repository.getStreak(today: today);
  }
}
