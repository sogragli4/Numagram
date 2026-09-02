import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';
import 'package:nonogram_daily/domain/usecases/word/apply_interest_selection.dart';
import 'package:nonogram_daily/domain/usecases/word/spend_category_change.dart';
import 'package:nonogram_daily/domain/usecases/word/unlock_next_section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'word_progress_controller.g.dart';

/// The already-loaded word progress at app start — overridden in `main()`
/// with the value read from `WordProgressRepository` before `runApp`,
/// same pattern as `initialAppSettingsProvider`.
final initialWordProgressProvider = Provider<WordProgress>((ref) {
  throw UnimplementedError(
    'initialWordProgressProvider must be overridden with loaded progress',
  );
});

@riverpod
class WordProgressController extends _$WordProgressController {
  @override
  WordProgress build() => ref.watch(initialWordProgressProvider);

  /// Records the survey selections and marks it seen — whether the
  /// player picked tags or skipped, either way it shouldn't show again.
  Future<void> applyInterestSelection(Set<String> selectedTagIds) => _update(
    const ApplyInterestSelection().call(
      progress: state,
      selectedTagIds: selectedTagIds,
    ),
  );

  /// Records [trackId]'s [sectionIndex] as solved. Idempotent — see
  /// `UnlockNextSection`'s doc comment.
  Future<void> unlockNextSection({
    required String trackId,
    required int sectionIndex,
  }) => _update(
    const UnlockNextSection().call(
      progress: state,
      trackId: trackId,
      sectionIndex: sectionIndex,
    ),
  );

  /// Caller is responsible for checking the quota
  /// (`WordProgress.categoryChangeCountFor` against
  /// `WordGameLimits.freeCategoryChangesPerDay`) and gating anything
  /// beyond it behind a rewarded ad — this just records the spend.
  Future<void> spendCategoryChange(String todayKey) => _update(
    const SpendCategoryChange().call(progress: state, todayKey: todayKey),
  );

  Future<void> _update(WordProgress progress) async {
    state = progress;
    await ref.read(wordProgressRepositoryProvider).updateProgress(progress);
  }
}
