import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';

void main() {
  group('WordProgress', () {
    test('defaults are empty/unset', () {
      expect(WordProgress.defaults.completedSectionKeys, isEmpty);
      expect(WordProgress.defaults.interestTagIds, isEmpty);
      expect(WordProgress.defaults.hasSeenInterestSurvey, isFalse);
      expect(WordProgress.defaults.categoryChangeDateKey, isNull);
      expect(WordProgress.defaults.categoryChangeCount, 0);
    });

    test('isSectionCompleted is true only for a recorded key', () {
      const progress = WordProgress(
        completedSectionKeys: {'demo#1'},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: null,
        categoryChangeCount: 0,
      );
      expect(progress.isSectionCompleted('demo', 1), isTrue);
      expect(progress.isSectionCompleted('demo', 2), isFalse);
      expect(progress.isSectionCompleted('tarih', 1), isFalse);
    });

    test('categoryChangeCountFor returns 0 on a different day', () {
      const progress = WordProgress(
        completedSectionKeys: {},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: '2026-09-01',
        categoryChangeCount: 2,
      );
      expect(progress.categoryChangeCountFor('2026-09-01'), 2);
      expect(progress.categoryChangeCountFor('2026-09-02'), 0);
    });

    test('copyWith updates only the given fields', () {
      final updated = WordProgress.defaults.copyWith(
        interestTagIds: {'tarih'},
        hasSeenInterestSurvey: true,
      );
      expect(updated.interestTagIds, {'tarih'});
      expect(updated.hasSeenInterestSurvey, isTrue);
      expect(updated.completedSectionKeys, isEmpty);
    });

    test('copyWith can set categoryChangeDateKey back to null', () {
      const progress = WordProgress(
        completedSectionKeys: {},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: '2026-09-01',
        categoryChangeCount: 1,
      );
      final updated = progress.copyWith(categoryChangeDateKey: () => null);
      expect(updated.categoryChangeDateKey, isNull);
    });
  });
}
