import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/core/theme.dart';

void main() {
  group('AppColorTheme', () {
    test('classic is always unlocked', () {
      expect(AppColorTheme.classic.isUnlockedAt(0), isTrue);
    });

    test('sunset unlocks at its required streak, not before', () {
      final required = AppColorTheme.sunset.requiredStreak;
      expect(AppColorTheme.sunset.isUnlockedAt(required - 1), isFalse);
      expect(AppColorTheme.sunset.isUnlockedAt(required), isTrue);
      expect(AppColorTheme.sunset.isUnlockedAt(required + 1), isTrue);
    });

    test('forest requires a longer streak than sunset', () {
      expect(
        AppColorTheme.forest.requiredStreak,
        greaterThan(AppColorTheme.sunset.requiredStreak),
      );
    });

    test('fromId round-trips every theme id', () {
      for (final theme in AppColorTheme.values) {
        expect(AppColorTheme.fromId(theme.id), theme);
      }
    });

    test('fromId falls back to classic for an unknown id', () {
      expect(AppColorTheme.fromId('does-not-exist'), AppColorTheme.classic);
    });
  });
}
