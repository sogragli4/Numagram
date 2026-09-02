import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';
import 'package:nonogram_daily/domain/engine/stable_hash.dart';

/// A canonical, cross-platform-stable fingerprint of a solved grid's cell
/// pattern. Deliberately not `PuzzleGrid.hashCode` (built on `Object.hash`,
/// which Dart does not promise is stable across SDK versions) — this test
/// exists specifically to catch a regression in *that* kind of stability.
int _fingerprint(
  int width,
  int height,
  bool Function(int row, int col) cellAt,
) {
  final buffer = StringBuffer();
  for (var r = 0; r < height; r++) {
    for (var c = 0; c < width; c++) {
      buffer.write(cellAt(r, c) ? '1' : '0');
    }
  }
  return fnv1a64(buffer.toString());
}

void main() {
  group('seedForDate', () {
    test('is a pure function of the calendar date', () {
      expect(seedForDate(DateTime(2026, 9)), seedForDate(DateTime(2026, 9)));
      expect(
        seedForDate(DateTime(2026, 9)),
        isNot(equals(seedForDate(DateTime(2026, 9, 2)))),
      );
    });

    test(
      'ignores time-of-day, so same-date timezone offsets are irrelevant',
      () {
        expect(
          seedForDate(DateTime(2026, 9)),
          seedForDate(DateTime(2026, 9, 1, 23, 59, 59)),
        );
      },
    );
  });

  group(
    'daily puzzle determinism: pinned dates -> pinned grid fingerprint',
    () {
      // Regenerating these on purpose (e.g. after a deliberate generator
      // change) is fine — just regenerate the expected values below and
      // note the change in CLAUDE.md. An *unexpected* failure here means a
      // past daily puzzle would silently change for existing players.
      const pinnedDates =
          <String, (int year, int month, int day, int expectedFingerprint)>{
            '2024-01-01': (2024, 1, 1, -4543252270062225592),
            '2025-06-15': (2025, 6, 15, 6709142790252214186),
            '2026-09-01': (2026, 9, 1, 4718093402722289905),
            '2030-12-31': (2030, 12, 31, 4299185636649034079),
          };

      for (final entry in pinnedDates.entries) {
        test(entry.key, () {
          final (year, month, day, expected) = entry.value;
          final seed = seedForDate(DateTime(year, month, day));
          final puzzle = generatePuzzle(seed: seed, width: 10, height: 10);
          final fingerprint = _fingerprint(10, 10, puzzle.solution.cellAt);
          expect(
            fingerprint,
            expected,
            reason:
                'Grid fingerprint for ${entry.key} changed. If this is an '
                'intentional generator change, update the pinned value and '
                "note it in CLAUDE.md — otherwise this date's puzzle just "
                'silently changed for every existing player.',
          );
        });
      }

      test('same seed reproduces the same puzzle across repeated runs', () {
        final seed = seedForDate(DateTime(2026, 9));
        final a = generatePuzzle(seed: seed, width: 10, height: 10);
        final b = generatePuzzle(seed: seed, width: 10, height: 10);
        expect(a.solution, equals(b.solution));
      });
    },
  );
}
