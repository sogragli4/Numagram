// ignore_for_file: avoid_print
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/engine/difficulty_scorer.dart';
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';

void main() {
  for (final size in [5, 8, 10, 12, 15]) {
    final counts = {for (final d in Difficulty.values) d: 0};
    const trials = 60;
    for (var seed = 0; seed < trials; seed++) {
      final puzzle = generatePuzzle(
        seed: seed * 7919 + size,
        width: size,
        height: size,
      );
      counts[puzzle.difficulty] = counts[puzzle.difficulty]! + 1;
    }
    print('size=$size -> $counts');
  }
}
