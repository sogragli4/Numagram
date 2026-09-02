import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/usecases/interstitial_gate.dart';

void main() {
  group('InterstitialGate', () {
    test('is never eligible outside free play', () {
      final gate = InterstitialGate()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion();
      expect(
        gate.isEligible(
          isFreePlay: false,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: true,
        ),
        isFalse,
      );
    });

    test('is never eligible during the first session', () {
      final gate = InterstitialGate()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion();
      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 1,
          hasCompletedFirstPuzzleEver: true,
        ),
        isFalse,
      );
    });

    test('is never eligible before the first completed puzzle ever', () {
      final gate = InterstitialGate()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion();
      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: false,
        ),
        isFalse,
      );
    });

    test('requires at least 3 completions since the last interstitial', () {
      final gate = InterstitialGate()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion();
      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: true,
        ),
        isFalse,
      );
      gate.recordFreePlayCompletion();
      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: true,
        ),
        isTrue,
      );
    });

    test('respects the 90 second cooldown after showing', () {
      var now = DateTime(2026, 1, 1, 12);
      // Show once, then rack up 3 more completions — immediately after,
      // it should still be blocked by the cooldown, not the counter.
      final gate = InterstitialGate(now: () => now)
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordShown()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion();
      now = now.add(const Duration(seconds: 60));
      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: true,
        ),
        isFalse,
        reason: 'only 60s have passed, cooldown is 90s',
      );

      now = now.add(const Duration(seconds: 31));
      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: true,
        ),
        isTrue,
      );
    });

    test('recordShown resets the completion counter', () {
      var now = DateTime(2026, 1, 1, 12);
      final gate = InterstitialGate(now: () => now)
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordFreePlayCompletion()
        ..recordShown();
      now = now.add(const Duration(minutes: 5));

      expect(
        gate.isEligible(
          isFreePlay: true,
          sessionCount: 2,
          hasCompletedFirstPuzzleEver: true,
        ),
        isFalse,
        reason: 'no completions recorded since the last show',
      );
    });
  });
}
