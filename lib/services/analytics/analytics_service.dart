/// Product analytics — the exact event set the Phase 4 spec calls for, so
/// the founder can tell whether ad load is hurting retention.
abstract class AnalyticsService {
  Future<void> logPuzzleStarted({
    required String source, // 'daily' | 'archive' | 'free_play'
    required int width,
    required int height,
  });

  Future<void> logPuzzleCompleted({
    required String source,
    required int elapsedSeconds,
    required bool perfect,
  });

  Future<void> logStreakExtended({required int streak});

  Future<void> logStreakBroken({required int previousStreak});

  Future<void> logRewardedShown({required String placement});

  Future<void> logRewardedCompleted({required String placement});

  Future<void> logInterstitialShown();

  Future<void> logHintUsed();

  Future<void> logSessionLength(Duration length);
}
