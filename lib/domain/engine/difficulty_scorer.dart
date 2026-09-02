import 'package:nonogram_daily/domain/entities/difficulty.dart';

/// Difficulty thresholds, tuned empirically (see
/// `test/domain/engine/difficulty_scorer_test.dart`) so that a 10x10
/// puzzle lands in [Difficulty.medium] on average.
const double _easyMediumBoundary = 2;
const double _mediumHardBoundary = 3.7;

/// Scores a solved puzzle from its grid size, how many solver sweeps
/// ([passCount]) it took to fully deduce, and how much of it was obvious
/// immediately ([firstPassDeducedFraction]).
///
/// Bigger grids, more sweeps, and a smaller first-pass fraction all push
/// the score up (harder); a high first-pass fraction pulls it down
/// (easier, because most of it falls out immediately).
Difficulty scoreDifficulty({
  required int width,
  required int height,
  required int passCount,
  required double firstPassDeducedFraction,
}) {
  final sizeFactor = (width * height) / 100.0;
  final passFactor = passCount.toDouble();
  final easeFactor = firstPassDeducedFraction;

  final score = sizeFactor + (passFactor * 0.8) - (easeFactor * 2.5);

  if (score < _easyMediumBoundary) return Difficulty.easy;
  if (score < _mediumHardBoundary) return Difficulty.medium;
  return Difficulty.hard;
}
