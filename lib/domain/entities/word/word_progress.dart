import 'package:meta/meta.dart';

/// Persisted progress for the word game — the `AppSettings` equivalent
/// for Kelime Bulmacası, added in Faz 3 alongside the rest of this
/// feature's persistence layer.
///
/// [completedSectionKeys] is the *only* stored unlock state — how many
/// sections of a track are unlocked is a derived count (completed-in-that-
/// track + 1), not separately persisted, the same "computed, never
/// stored" reasoning `StreakRecord.compute` already uses for Nonogram's
/// streaks: one source of truth, nothing to desync.
@immutable
class WordProgress {
  const WordProgress({
    required this.completedSectionKeys,
    required this.interestTagIds,
    required this.hasSeenInterestSurvey,
    required this.categoryChangeDateKey,
    required this.categoryChangeCount,
  });

  static const defaults = WordProgress(
    completedSectionKeys: {},
    interestTagIds: {},
    hasSeenInterestSurvey: false,
    categoryChangeDateKey: null,
    categoryChangeCount: 0,
  );

  /// `"<trackId>#<sectionIndex>"` keys — one per solved section, across
  /// every track. A `Set`, not a count, so completion can be queried per
  /// section without re-deriving it from history.
  final Set<String> completedSectionKeys;

  /// The player's onboarding-survey (or later, Ayarlar-edited) interest
  /// tag selections — see `InterestProfile`. Kept as a plain `Set<String>`
  /// here (rather than embedding `InterestProfile` itself) so this entity
  /// has no dependency direction to worry about; `ApplyInterestSelection`
  /// is the one place that cares about the richer type.
  final Set<String> interestTagIds;

  /// Whether the ilgi alanı anketi has been shown (and either completed
  /// or explicitly skipped) at least once.
  final bool hasSeenInterestSurvey;

  /// `yyyy-MM-dd` the day [categoryChangeCount] applies to; `null` before
  /// the player has ever changed category/track. A different key than
  /// "today" means the count has implicitly reset — see
  /// [categoryChangeCountFor].
  final String? categoryChangeDateKey;
  final int categoryChangeCount;

  bool isSectionCompleted(String trackId, int sectionIndex) =>
      completedSectionKeys.contains('$trackId#$sectionIndex');

  /// Category/track changes already spent on [todayKey] — 0 if that's not
  /// the date [categoryChangeCount] was tracking (i.e. the day rolled
  /// over).
  int categoryChangeCountFor(String todayKey) =>
      categoryChangeDateKey == todayKey ? categoryChangeCount : 0;

  WordProgress copyWith({
    Set<String>? completedSectionKeys,
    Set<String>? interestTagIds,
    bool? hasSeenInterestSurvey,
    String? Function()? categoryChangeDateKey,
    int? categoryChangeCount,
  }) => WordProgress(
    completedSectionKeys: completedSectionKeys ?? this.completedSectionKeys,
    interestTagIds: interestTagIds ?? this.interestTagIds,
    hasSeenInterestSurvey: hasSeenInterestSurvey ?? this.hasSeenInterestSurvey,
    categoryChangeDateKey: categoryChangeDateKey != null
        ? categoryChangeDateKey()
        : this.categoryChangeDateKey,
    categoryChangeCount: categoryChangeCount ?? this.categoryChangeCount,
  );
}
