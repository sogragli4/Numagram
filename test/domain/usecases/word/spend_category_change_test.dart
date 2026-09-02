import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/entities/word/word_progress.dart';
import 'package:nonogram_daily/domain/usecases/word/spend_category_change.dart';

void main() {
  group('SpendCategoryChange', () {
    const usecase = SpendCategoryChange();

    test('sets the count to 1 on the first spend of a new day', () {
      final updated = usecase(
        progress: WordProgress.defaults,
        todayKey: '2026-09-01',
      );
      expect(updated.categoryChangeDateKey, '2026-09-01');
      expect(updated.categoryChangeCount, 1);
    });

    test('increments the count for a second spend the same day', () {
      const progress = WordProgress(
        completedSectionKeys: {},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: '2026-09-01',
        categoryChangeCount: 1,
      );
      final updated = usecase(progress: progress, todayKey: '2026-09-01');
      expect(updated.categoryChangeCount, 2);
    });

    test('resets to 1 when the day has rolled over', () {
      const progress = WordProgress(
        completedSectionKeys: {},
        interestTagIds: {},
        hasSeenInterestSurvey: false,
        categoryChangeDateKey: '2026-09-01',
        categoryChangeCount: 2,
      );
      final updated = usecase(progress: progress, todayKey: '2026-09-02');
      expect(updated.categoryChangeDateKey, '2026-09-02');
      expect(updated.categoryChangeCount, 1);
    });
  });
}
