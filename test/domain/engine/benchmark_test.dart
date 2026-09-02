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
}
