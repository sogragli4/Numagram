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
