import 'package:nonogram_daily/domain/engine/deterministic_random.dart';
import 'package:nonogram_daily/domain/engine/difficulty_scorer.dart';
import 'package:nonogram_daily/domain/engine/full_solver.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';

class PuzzleGenerationException implements Exception {
  PuzzleGenerationException(this.message);

  final String message;

  @override
  String toString() => 'PuzzleGenerationException: $message';
}

const int _maxAttemptsPerSize = 500;
const int _minFallbackDimension = 5;
const double _minDensity = 0.50;
const double _densitySpan = 0.12; // density range is [0.50, 0.62]

/// Generates a puzzle that is guaranteed to have exactly one solution,
/// reachable without guessing, for the given [seed].
///
/// Tries [width] x [height] first; if no attempt within the budget yields a
/// solvable puzzle, falls back to a smaller size (both dimensions reduced
/// by 1, down to [_minFallbackDimension]) before giving up.
Puzzle generatePuzzle({
  required int seed,
  required int width,
  required int height,
}) {
  var w = width;
  var h = height;
  while (true) {
    final attempt = _tryGenerateAtSize(seed: seed, width: w, height: h);
    if (attempt != null) return attempt;

    if (w <= _minFallbackDimension && h <= _minFallbackDimension) {
      throw PuzzleGenerationException(
        'Could not generate a uniquely-solvable puzzle for seed=$seed '
        'starting at $width x $height, even after falling back to '
        '$_minFallbackDimension x $_minFallbackDimension.',
      );
    }
    w = w > _minFallbackDimension ? w - 1 : w;
    h = h > _minFallbackDimension ? h - 1 : h;
  }
}

Puzzle? _tryGenerateAtSize({
  required int seed,
  required int width,
  required int height,
}) {
  // Salt by size so that falling back to a smaller size (or requesting a
  // different size with the same seed, e.g. free play) doesn't replay the
  // exact same random stream.
  final salted = seed ^ (width * 1000003) ^ (height * 97);
  final rng = DeterministicRandom(salted);
  final cellCount = width * height;

  for (var attempt = 0; attempt < _maxAttemptsPerSize; attempt++) {
    final density = _minDensity + rng.nextDouble() * _densitySpan;
    final cells = List<bool>.generate(cellCount, (_) => rng.nextBool(density));

    if (_hasEmptyLine(cells, width, height)) continue;

    final rowClues = List.generate(
      height,
      (r) => LineClue.fromCells(cells.sublist(r * width, r * width + width)),
    );
    final columnClues = List.generate(
      width,
      (c) => LineClue.fromCells([
        for (var r = 0; r < height; r++) cells[r * width + c],
      ]),
    );

    final solverResult = solveFull(
      width: width,
      height: height,
      rowClues: rowClues,
      columnClues: columnClues,
    );
    if (solverResult.outcome != SolverOutcome.solved) continue;

    final difficulty = scoreDifficulty(
      width: width,
      height: height,
      passCount: solverResult.passCount,
      firstPassDeducedFraction: solverResult.firstPassDeducedFraction,
    );

    return Puzzle(
      solution: PuzzleGrid.fromBools(width, height, cells),
      rowClues: rowClues,
      columnClues: columnClues,
      difficulty: difficulty,
      seed: seed,
      size: GridSize(width, height),
    );
  }
  return null;
}

bool _hasEmptyLine(List<bool> cells, int width, int height) {
  for (var r = 0; r < height; r++) {
    var anyFilled = false;
    for (var c = 0; c < width; c++) {
      if (cells[r * width + c]) {
        anyFilled = true;
        break;
      }
    }
    if (!anyFilled) return true;
  }
  for (var c = 0; c < width; c++) {
    var anyFilled = false;
    for (var r = 0; r < height; r++) {
      if (cells[r * width + c]) {
        anyFilled = true;
        break;
      }
    }
    if (!anyFilled) return true;
  }
  return false;
}
