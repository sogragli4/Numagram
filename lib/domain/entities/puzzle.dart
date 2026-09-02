import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';

/// A fully generated, guaranteed-unique, guaranteed-human-solvable nonogram.
class Puzzle {
  Puzzle({
    required this.solution,
    required this.rowClues,
    required this.columnClues,
    required this.difficulty,
    required this.seed,
    required this.size,
  }) {
    if (rowClues.length != size.height) {
      throw ArgumentError(
        'Expected ${size.height} row clues, got ${rowClues.length}.',
      );
    }
    if (columnClues.length != size.width) {
      throw ArgumentError(
        'Expected ${size.width} column clues, got ${columnClues.length}.',
      );
    }
    if (solution.width != size.width || solution.height != size.height) {
      throw ArgumentError(
        'Solution grid is ${solution.width} x ${solution.height} but size '
        'is $size.',
      );
    }
  }

  final PuzzleGrid solution;
  final List<LineClue> rowClues;
  final List<LineClue> columnClues;
  final Difficulty difficulty;
  final int seed;
  final GridSize size;
}
