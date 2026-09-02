import 'package:flutter/foundation.dart';
import 'package:nonogram_daily/domain/engine/puzzle_generator.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';

/// Runs [generatePuzzle] on a background isolate via [compute] — the one
/// locked requirement generation must satisfy ("Pure Dart, runs inside an
/// Isolate"). This is the only place in the app that's allowed to import
/// both the pure-Dart engine and `dart:ui`/Flutter's isolate helper.
class PuzzleGeneratorDataSource {
  const PuzzleGeneratorDataSource();

  Future<Puzzle> generate({
    required int seed,
    required int width,
    required int height,
  }) {
    return compute(_generateInIsolate, _GenerateArgs(seed, width, height));
  }
}

class _GenerateArgs {
  const _GenerateArgs(this.seed, this.width, this.height);
  final int seed;
  final int width;
  final int height;
}

Puzzle _generateInIsolate(_GenerateArgs args) =>
    generatePuzzle(seed: args.seed, width: args.width, height: args.height);
