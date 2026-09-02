import 'package:nonogram_daily/domain/entities/word/word_progress.dart';

/// Spends one of the player's daily free interest/category changes
/// (`WordGameLimits.freeCategoryChangesPerDay`) — the same date-keyed
/// daily-counter pattern as `AppSettings.archiveUnlocksCountFor` /
/// `AppSettingsController.recordArchiveUnlock`. The caller is
/// responsible for checking `WordProgress.categoryChangeCountFor` against
/// the quota (and gating the 3rd+ change behind a rewarded ad) before
/// calling this — it just records the spend.
class SpendCategoryChange {
  const SpendCategoryChange();

  WordProgress call({
    required WordProgress progress,
    required String todayKey,
  }) => progress.copyWith(
    categoryChangeDateKey: () => todayKey,
    categoryChangeCount: progress.categoryChangeCountFor(todayKey) + 1,
  );
}
