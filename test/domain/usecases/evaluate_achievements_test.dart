import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/achievement.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/statistics.dart';
import 'package:nonogram_daily/domain/usecases/evaluate_achievements.dart';

bool _unlocked(List<Achievement> achievements, AchievementId id) =>
    achievements.singleWhere((a) => a.id == id).isUnlocked;

void main() {
  group('evaluateAchievements', () {
    test('everything is locked with no completions and no streak', () {
      final achievements = evaluateAchievements(
        statistics: Statistics.empty,
        longestStreak: 0,
      );
      expect(achievements, everyElement(isA<Achievement>()));
      expect(achievements.every((a) => !a.isUnlocked), isTrue);
      // Exactly one row per AchievementId — the presentation layer
      // renders this as a fixed grid, so a duplicate or missing id
      // would be a real bug, not just noise.
      expect(
        achievements.map((a) => a.id).toSet(),
        AchievementId.values.toSet(),
      );
    });

    test('solved-count badges unlock at their exact thresholds', () {
      Statistics withTotal(int total) => Statistics(
        totalSolved: total,
        perfectCount: 0,
        averageSecondsBySize: const {},
      );

      for (final total in [0, 1, 9, 10, 49, 50, 99, 100]) {
        final achievements = evaluateAchievements(
          statistics: withTotal(total),
          longestStreak: 0,
        );
        expect(
          _unlocked(achievements, AchievementId.firstPuzzle),
          total >= 1,
          reason: 'total=$total',
        );
        expect(
          _unlocked(achievements, AchievementId.tenPuzzles),
          total >= 10,
          reason: 'total=$total',
        );
        expect(
          _unlocked(achievements, AchievementId.fiftyPuzzles),
          total >= 50,
          reason: 'total=$total',
        );
        expect(
          _unlocked(achievements, AchievementId.hundredPuzzles),
          total >= 100,
          reason: 'total=$total',
        );
      }
    });

    test('perfect-count badges unlock at their exact thresholds', () {
      Statistics withPerfect(int perfect) => Statistics(
        totalSolved: perfect,
        perfectCount: perfect,
        averageSecondsBySize: const {},
      );

      final justUnderTen = evaluateAchievements(
        statistics: withPerfect(9),
        longestStreak: 0,
      );
      expect(_unlocked(justUnderTen, AchievementId.firstPerfect), isTrue);
      expect(_unlocked(justUnderTen, AchievementId.tenPerfect), isFalse);

      final tenExactly = evaluateAchievements(
        statistics: withPerfect(10),
        longestStreak: 0,
      );
      expect(_unlocked(tenExactly, AchievementId.tenPerfect), isTrue);
    });

    test('streak badges unlock at 3, 7, and 30 days, not before', () {
      for (final streak in [2, 3, 6, 7, 29, 30]) {
        final achievements = evaluateAchievements(
          statistics: Statistics.empty,
          longestStreak: streak,
        );
        expect(
          _unlocked(achievements, AchievementId.threeDayStreak),
          streak >= 3,
          reason: 'streak=$streak',
        );
        expect(
          _unlocked(achievements, AchievementId.sevenDayStreak),
          streak >= 7,
          reason: 'streak=$streak',
        );
        expect(
          _unlocked(achievements, AchievementId.thirtyDayStreak),
          streak >= 30,
          reason: 'streak=$streak',
        );
      }
    });

    test('"big thinker" unlocks for any solved size >= 15 on either side', () {
      final unsolved = evaluateAchievements(
        statistics: Statistics(
          totalSolved: 1,
          perfectCount: 0,
          averageSecondsBySize: {const GridSize(10, 10): 120},
        ),
        longestStreak: 0,
      );
      expect(_unlocked(unsolved, AchievementId.bigThinker), isFalse);

      final solved = evaluateAchievements(
        statistics: Statistics(
          totalSolved: 1,
          perfectCount: 0,
          averageSecondsBySize: {const GridSize(15, 15): 200},
        ),
        longestStreak: 0,
      );
      expect(_unlocked(solved, AchievementId.bigThinker), isTrue);
    });

    test('"go big" unlocks only for exactly the 20x20 Free Play size', () {
      final fifteenOnly = evaluateAchievements(
        statistics: Statistics(
          totalSolved: 1,
          perfectCount: 0,
          averageSecondsBySize: {const GridSize(15, 15): 200},
        ),
        longestStreak: 0,
      );
      expect(_unlocked(fifteenOnly, AchievementId.goBig), isFalse);

      final twentyByTwenty = evaluateAchievements(
        statistics: Statistics(
          totalSolved: 1,
          perfectCount: 0,
          averageSecondsBySize: {const GridSize(20, 20): 400},
        ),
        longestStreak: 0,
      );
      expect(_unlocked(twentyByTwenty, AchievementId.goBig), isTrue);
    });
  });
}
