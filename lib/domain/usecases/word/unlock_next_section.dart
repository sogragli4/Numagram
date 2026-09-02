import 'package:nonogram_daily/domain/entities/word/word_progress.dart';

/// Marks a section solved — the word-puzzle equivalent of
/// `AppColorTheme.isUnlockedAt` / `FreePlaySizePreset.isUnlockedAt`, but
/// keyed to completion rather than a streak. The *next* section's
/// availability is a derived fact (see `WordProgress`'s doc comment),
/// not something this usecase writes directly.
///
/// Idempotent: re-solving an already-completed section (replaying an
/// archive puzzle) is a no-op, the same "first completion is the one
/// that counts" reasoning `IsarLocalDataSource.saveCompletion` already
/// uses for Nonogram.
class UnlockNextSection {
  const UnlockNextSection();

  WordProgress call({
    required WordProgress progress,
    required String trackId,
    required int sectionIndex,
  }) {
    final key = '$trackId#$sectionIndex';
    if (progress.completedSectionKeys.contains(key)) return progress;
    return progress.copyWith(
      completedSectionKeys: {...progress.completedSectionKeys, key},
    );
  }
}
