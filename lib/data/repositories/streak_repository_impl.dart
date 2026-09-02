import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';
import 'package:nonogram_daily/domain/entities/statistics.dart';
import 'package:nonogram_daily/domain/entities/streak_record.dart';
import 'package:nonogram_daily/domain/repositories/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  const StreakRepositoryImpl(this._dataSource);

  final IsarLocalDataSource _dataSource;

  @override
  Future<void> recordCompletion(PuzzleCompletion completion) =>
      _dataSource.saveCompletion(PuzzleCompletionModel.fromEntity(completion));

  @override
  Future<StreakRecord> getStreak({required DateTime today}) async {
    final dates = await getCompletedDates();
    return StreakRecord.compute(completedDates: dates, today: today);
  }

  @override
  Future<Set<DateTime>> getCompletedDates() async {
    final all = await _dataSource.allCompletions();
    return {
      for (final model in all)
        if (model.dateKey != null) parseDateKey(model.dateKey!),
    };
  }

  @override
  Future<Statistics> getStatistics() async {
    final all = await _dataSource.allCompletions();
    if (all.isEmpty) return Statistics.empty;

    final perfectCount = all.where((m) => m.mistakeCount == 0).length;
    final secondsBySize = <GridSize, List<int>>{};
    for (final model in all) {
      secondsBySize
          .putIfAbsent(GridSize(model.width, model.height), () => [])
          .add(model.elapsedSeconds);
    }

    return Statistics(
      totalSolved: all.length,
      perfectCount: perfectCount,
      averageSecondsBySize: {
        for (final entry in secondsBySize.entries)
          entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
      },
    );
  }
}
