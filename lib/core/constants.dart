/// Kill switches for each Phase 4 ad placement. Flip one to `false` and
/// rebuild to pull that placement without touching call sites — the
/// Phase 4 spec's "remotely-ish" requirement, satisfied with a plain
/// local constant rather than a remote-config service (there's no
/// backend in this app, by design).
abstract final class FeatureFlags {
  static const bool hintRewardedAdEnabled = true;
  static const bool extraHeartRewardedAdEnabled = true;
  static const bool archiveUnlockRewardedAdEnabled = true;
  static const bool interstitialAdEnabled = true;
  static const bool bannerAdEnabled = true;
}

/// Gameplay limits that happen to gate a monetized action.
abstract final class GameLimits {
  /// Rewarded hint watches allowed per puzzle (Phase 4 spec).
  static const int maxHintsPerPuzzle = 3;

  /// Archive puzzles a free user can open per calendar day before the
  /// "unlock via rewarded ad" gate kicks in (Phase 4 spec).
  static const int freeArchivePuzzlesPerDay = 3;
}

/// Interstitial frequency capping (Phase 4 spec: "minimum 90 seconds
/// between interstitials, and never more than 1 per 3 completions").
abstract final class AdLimits {
  static const Duration interstitialCooldown = Duration(seconds: 90);
  static const int interstitialMinCompletions = 3;
}

/// Kelime Bulmacası (word game) progression limits — CLAUDE.MD, "Kelime
/// Bulmacası" bölüm 4 (category-change quota).
abstract final class WordGameLimits {
  /// Free category/track switches per calendar day before the
  /// "unlock via rewarded ad" gate kicks in — same shape as
  /// [GameLimits.freeArchivePuzzlesPerDay], just a different daily
  /// counter (`WordProgress.categoryChangeCountFor`).
  static const int freeCategoryChangesPerDay = 2;
}

/// Longest-streak milestones that unlock the Phase 5 colour themes — by
/// streak, never by ad (spec is explicit about this).
abstract final class ThemeUnlocks {
  static const int sunsetStreakDays = 7;
  static const int forestStreakDays = 30;
}

/// Longest-streak milestone that unlocks the Extra Large Free Play size —
/// by streak, never by ad, same reasoning as [ThemeUnlocks]. Sits between
/// the two theme milestones so progression keeps unfolding gradually
/// rather than clustering everything at 7 or 30 days.
abstract final class FreePlaySizeUnlocks {
  static const int extraLargeStreakDays = 14;
}

/// Thresholds for the collectible achievement badges (see
/// `domain/entities/achievement.dart`). Purely cosmetic recognition,
/// derived entirely from already-persisted stats/streak data — nothing
/// new to track, and (same rule as every other unlock in this app) never
/// gated behind an ad.
abstract final class AchievementThresholds {
  static const int tenPuzzles = 10;
  static const int fiftyPuzzles = 50;
  static const int hundredPuzzles = 100;
  static const int tenPerfect = 10;

  /// A near-term streak milestone, deliberately short of
  /// [ThemeUnlocks.sunsetStreakDays] — an early "you're building a habit"
  /// nudge before the first cosmetic unlock lands.
  static const int earlyStreakDays = 3;

  /// Minimum side length for the "solved a big puzzle" badge.
  static const int bigPuzzleMinSide = 15;
}

/// Streak freeze: missing a single day doesn't break the streak if a
/// freeze is available (see `domain/usecases/streak_freeze.dart`) — the
/// biggest single churn driver in daily-puzzle apps is "missed one day,
/// felt the streak was already ruined, stopped opening the app."
abstract final class StreakFreezeConfig {
  /// Every player starts with one, so the very first missed day is
  /// already covered.
  static const int startingFreezes = 1;

  /// Freezes never stockpile past this — a safety net, not a resource to
  /// hoard indefinitely.
  static const int maxFreezesHeld = 2;

  /// Freezes granted per new calendar month, up to [maxFreezesHeld].
  static const int monthlyGrant = 1;
}
