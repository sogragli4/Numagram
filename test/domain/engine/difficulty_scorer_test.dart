import 'package:flutter_test/flutter_test.dart';
import 'package:nonogram_daily/domain/engine/difficulty_scorer.dart';
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';

void main() {
  group('scoreDifficulty', () {
    test('a small puzzle solved in one obvious pass is easy', () {
      final difficulty = scoreDifficulty(
        width: 5,
        height: 5,
        passCount: 1,
        firstPassDeducedFraction: 1,
      );
      expect(difficulty, Difficulty.easy);
    });

    test(
      'a large puzzle needing many passes with little upfront progress is hard',
      () {
        final difficulty = scoreDifficulty(
          width: 15,
          height: 15,
          passCount: 6,
          firstPassDeducedFraction: 0.1,
        );
        expect(difficulty, Difficulty.hard);
      },
    );

    test('more passes and a smaller first-pass fraction never make a puzzle '
        'easier', () {
      final easier = scoreDifficulty(
        width: 10,
        height: 10,
        passCount: 2,
        firstPassDeducedFraction: 0.5,
      );
      final harder = scoreDifficulty(
        width: 10,
        height: 10,
        passCount: 4,
        firstPassDeducedFraction: 0.2,
      );
      expect(
        Difficulty.values.indexOf(harder),
        greaterThanOrEqualTo(Difficulty.values.indexOf(easier)),
      );
    });
  });

  group('difficulty calibration against the real generator', () {
    test('10x10 is the most common difficulty for a 10x10 puzzle', () {
      // Per the Phase 1 spec: "Tune so a 10x10 lands in medium." Checked
      // against the actual generator (not synthetic inputs) across many
      // seeds, since a single puzzle's difficulty is seed-dependent.
      final counts = {for (final d in Difficulty.values) d: 0};
      const trials = 60;
      for (var seed = 0; seed < trials; seed++) {
        final puzzle = generatePuzzle(
          seed: seed * 7919 + 10,
          width: 10,
          height: 10,
        );
        counts[puzzle.difficulty] = counts[puzzle.difficulty]! + 1;
      }
      final mode = counts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      expect(
        mode,
        Difficulty.medium,
        reason: '10x10 difficulty distribution was $counts',
      );
    });

    test('difficulty trends harder as grid size grows', () {
      double hardFraction(int size) {
        const trials = 40;
        var hard = 0;
        for (var seed = 0; seed < trials; seed++) {
          final puzzle = generatePuzzle(
            seed: seed * 7919 + size,
            width: size,
            height: size,
          );
          if (puzzle.difficulty == Difficulty.hard) hard++;
        }
        return hard / trials;
      }

      final small = hardFraction(5);
      final large = hardFraction(15);
      expect(large, greaterThan(small));
    });
  });
}
