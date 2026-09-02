import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';
import 'package:nonogram_daily/domain/usecases/word/unlock_next_section.dart';

void main() {
  group('UnlockNextSection', () {
    const usecase = UnlockNextSection();

    test('adds the trackId#sectionIndex key to completedSectionKeys', () {
      final updated = usecase(
        progress: WordProgress.defaults,
        trackId: 'demo',
        sectionIndex: 1,
      );
      expect(updated.completedSectionKeys, {'demo#1'});
    });

    test('is idempotent for an already-completed section', () {
      const progress = WordProgress(
        completedSectionKeys: {'demo#1'},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: null,
        categoryChangeCount: 0,
      );
      final updated = usecase(
        progress: progress,
        trackId: 'demo',
        sectionIndex: 1,
      );
      expect(identical(updated, progress), isTrue);
    });

    test('keeps existing completions from other tracks/sections', () {
      const progress = WordProgress(
        completedSectionKeys: {'demo#1'},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: null,
        categoryChangeCount: 0,
      );
      final updated = usecase(
        progress: progress,
        trackId: 'tarih',
        sectionIndex: 1,
      );
      expect(updated.completedSectionKeys, {'demo#1', 'tarih#1'});
    });
  });
}
