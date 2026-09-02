import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/domain/entities/achievement.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/statistics.dart';

/// The size Free Play's streak-unlocked "Extra Large" preset plays at
/// (see `free_play_screen.dart`) — the "Go Big" badge tracks having
/// actually solved one, not just unlocked the option.
const _extraLargeSize = GridSize(20, 20);

/// Derives every [Achievement]'s unlock state from already-persisted
/// data — [statistics] and [longestStreak] — rather than tracking
/// unlocked/not separately. Same reasoning as `StreakRecord.compute`:
/// one source of truth, nothing to desync. Pure and order-stable, so the
/// presentation layer can render the result directly as a fixed grid.
List<Achievement> evaluateAchievements({
  required Statistics statistics,
  required int longestStreak,
}) {
  final solvedSizes = statistics.averageSecondsBySize.keys;
  final solvedABigPuzzle = solvedSizes.any(
    (size) =>
        size.width >= AchievementThresholds.bigPuzzleMinSide ||
        size.height >= AchievementThresholds.bigPuzzleMinSide,
  );

  return [
    Achievement(
      id: AchievementId.firstPuzzle,
      isUnlocked: statistics.totalSolved >= 1,
    ),
    Achievement(
      id: AchievementId.tenPuzzles,
      isUnlocked: statistics.totalSolved >= AchievementThresholds.tenPuzzles,
    ),
    Achievement(
      id: AchievementId.fiftyPuzzles,
      isUnlocked: statistics.totalSolved >= AchievementThresholds.fiftyPuzzles,
    ),
    Achievement(
      id: AchievementId.hundredPuzzles,
      isUnlocked:
          statistics.totalSolved >= AchievementThresholds.hundredPuzzles,
    ),
    Achievement(
      id: AchievementId.firstPerfect,
      isUnlocked: statistics.perfectCount >= 1,
    ),
    Achievement(
      id: AchievementId.tenPerfect,
      isUnlocked: statistics.perfectCount >= AchievementThresholds.tenPerfect,
    ),
    Achievement(
      id: AchievementId.threeDayStreak,
      isUnlocked: longestStreak >= AchievementThresholds.earlyStreakDays,
    ),
    Achievement(
      id: AchievementId.sevenDayStreak,
      isUnlocked: longestStreak >= ThemeUnlocks.sunsetStreakDays,
    ),
    Achievement(
      id: AchievementId.thirtyDayStreak,
      isUnlocked: longestStreak >= ThemeUnlocks.forestStreakDays,
    ),
    Achievement(id: AchievementId.bigThinker, isUnlocked: solvedABigPuzzle),
    Achievement(
      id: AchievementId.goBig,
      isUnlocked: solvedSizes.contains(_extraLargeSize),
    ),
  ];
}
