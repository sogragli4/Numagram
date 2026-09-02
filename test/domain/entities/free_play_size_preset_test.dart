import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/domain/entities/free_play_size_preset.dart';

void main() {
  group('FreePlaySizePreset.isUnlockedAt', () {
    test('a preset with no required streak is always unlocked', () {
      const preset = FreePlaySizePreset(5, 5);
      expect(preset.isUnlockedAt(0), isTrue);
      expect(preset.isUnlockedAt(100), isTrue);
    });

    test('is locked below the required streak', () {
      const preset = FreePlaySizePreset(20, 20, requiredStreak: 14);
      expect(preset.isUnlockedAt(13), isFalse);
    });

    test('unlocks exactly at the required streak', () {
      const preset = FreePlaySizePreset(20, 20, requiredStreak: 14);
      expect(preset.isUnlockedAt(14), isTrue);
    });

    test('stays unlocked above the required streak', () {
      const preset = FreePlaySizePreset(20, 20, requiredStreak: 14);
      expect(preset.isUnlockedAt(365), isTrue);
    });
  });

  group('freePlaySizePresets', () {
    test('is ordered smallest to largest, matching the screen labels', () {
      final sizes = freePlaySizePresets.map((p) => (p.width, p.height));
      expect(sizes, [(5, 5), (10, 10), (15, 15), (20, 20)]);
    });

    test('only the largest preset requires a streak', () {
      expect(
        freePlaySizePresets
            .take(freePlaySizePresets.length - 1)
            .every((p) => p.requiredStreak == 0),
        isTrue,
      );
      expect(
        freePlaySizePresets.last.requiredStreak,
        FreePlaySizeUnlocks.extraLargeStreakDays,
      );
    });
  });
}
