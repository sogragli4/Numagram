import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';
import 'package:nonogram_daily/domain/usecases/word/apply_interest_selection.dart';

void main() {
  group('ApplyInterestSelection', () {
    const usecase = ApplyInterestSelection();

    test('records the selected tags and marks the survey seen', () {
      final updated = usecase(
        progress: WordProgress.defaults,
        selectedTagIds: {'tarih', 'hukuk'},
      );
      expect(updated.interestTagIds, {'tarih', 'hukuk'});
      expect(updated.hasSeenInterestSurvey, isTrue);
    });

    test('marks the survey seen even with an empty selection (a skip)', () {
      final updated = usecase(
        progress: WordProgress.defaults,
        selectedTagIds: {},
      );
      expect(updated.interestTagIds, isEmpty);
      expect(updated.hasSeenInterestSurvey, isTrue);
    });

    test('replaces a previous selection rather than merging it', () {
      const progress = WordProgress(
        completedSectionKeys: {},
        interestTagIds: {'tarih'},
        hasSeenInterestSurvey: true,
        categoryChangeDateKey: null,
        categoryChangeCount: 0,
      );
      final updated = usecase(progress: progress, selectedTagIds: {'hukuk'});
      expect(updated.interestTagIds, {'hukuk'});
    });
  });
}
