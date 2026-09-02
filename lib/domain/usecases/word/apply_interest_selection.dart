import 'package:nonogram_daily/domain/entities/word/word_progress.dart';

/// Persists the player's onboarding-survey (or later, Ayarlar-edited)
/// interest tag selections, and marks the survey seen — whether the
/// player picked something or explicitly skipped, either way it
/// shouldn't show again automatically (same pattern as
/// `AppSettingsController.markTutorialSeen`).
class ApplyInterestSelection {
  const ApplyInterestSelection();

  WordProgress call({
    required WordProgress progress,
    required Set<String> selectedTagIds,
  }) => progress.copyWith(
    interestTagIds: selectedTagIds,
    hasSeenInterestSurvey: true,
  );
}
