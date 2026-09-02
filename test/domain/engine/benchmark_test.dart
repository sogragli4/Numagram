import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';

void main() {
  test('15x15 generation completes well under the 300ms budget', () {
    // Warm up the JIT so we're measuring the algorithm, not compilation.
    generatePuzzle(seed: 0, width: 15, height: 15);

    const trials = 20;
    final timings = <int>[];
    for (var seed = 1; seed <= trials; seed++) {
      final stopwatch = Stopwatch()..start();
      generatePuzzle(seed: seed * 104729, width: 15, height: 15);
      stopwatch.stop();
      timings.add(stopwatch.elapsedMilliseconds);
    }

    final worst = timings.reduce((a, b) => a > b ? a : b);
    expect(
      worst,
      lessThan(300),
      reason:
          '15x15 generation timings (ms): $timings. This measures dev '
          'hardware, which is faster than the mid-range mobile device '
          'budget the 300ms figure targets — a failure here is a real '
          'regression, not noise.',
    );
  });

  test("20x20 generation (Free Play's streak-unlocked size) stays fast", () {
    // Not part of the original Phase 1 spec's pinned 300ms/15x15 budget —
    // added once 20x20 became a real, player-reachable size (see
    // `FreePlaySizeUnlocks`). A looser budget than 15x15's: a bigger grid
    // has more to search, and this is a one-off "unlock" moment rather
    // than every day's puzzle.
    generatePuzzle(seed: 0, width: 20, height: 20);

    const trials = 20;
    final timings = <int>[];
    for (var seed = 1; seed <= trials; seed++) {
      final stopwatch = Stopwatch()..start();
      generatePuzzle(seed: seed * 104729, width: 20, height: 20);
      stopwatch.stop();
      timings.add(stopwatch.elapsedMilliseconds);
    }

    final worst = timings.reduce((a, b) => a > b ? a : b);
    expect(
      worst,
      lessThan(1000),
      reason:
          '20x20 generation timings (ms): $timings. Same dev-hardware-vs '
          'mobile-budget reasoning as the 15x15 benchmark above.',
    );
  });
}
