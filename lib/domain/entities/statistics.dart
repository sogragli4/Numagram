import 'package:nonogram_daily/domain/entities/grid_size.dart';

/// Aggregate stats for the statistics screen: total solved, perfect
/// (no-mistake) count, and average solve time per grid size.
class Statistics {
  const Statistics({
    required this.totalSolved,
    required this.perfectCount,
    required this.averageSecondsBySize,
  });

  static const empty = Statistics(
    totalSolved: 0,
    perfectCount: 0,
    averageSecondsBySize: {},
  );

  final int totalSolved;
  final int perfectCount;
  final Map<GridSize, double> averageSecondsBySize;
}
