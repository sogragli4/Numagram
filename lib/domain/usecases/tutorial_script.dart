import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/line_clue.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';
import 'package:nonogram_daily/domain/entities/tutorial_step.dart';

/// The fixed, hand-authored puzzle used to teach nonogram logic: a plus
/// shape. Its clues cleanly demonstrate two techniques —
/// "a clue equal to the line length fills the whole line" (row/column 2,
/// clue `5`) and "a known filled cell plus a clue of `1` forces every
/// other cell in that line empty" (every other row/column, clue `1`).
///
/// Fixed rather than randomly generated: [buildTutorialScript] references
/// exact cell coordinates, which only makes sense against a puzzle that
/// never changes.
Puzzle buildTutorialPuzzle() {
  const solutionCells = [
    false, false, true, false, false, //
    false, false, true, false, false, //
    true, true, true, true, true, //
    false, false, true, false, false, //
    false, false, true, false, false, //
  ];
  final solution = PuzzleGrid.fromBools(5, 5, solutionCells);
  final rowClues = [
    for (var r = 0; r < 5; r++) LineClue.fromCells(solution.rowCells(r)),
  ];
  final columnClues = [
    for (var c = 0; c < 5; c++) LineClue.fromCells(solution.columnCells(c)),
  ];
  return Puzzle(
    solution: solution,
    rowClues: rowClues,
    columnClues: columnClues,
    difficulty: Difficulty.easy,
    seed: 0,
    size: const GridSize(5, 5),
  );
}

/// The ordered coaching script for [buildTutorialPuzzle]: fill the full
/// row, notice the engine auto-marking the now-satisfied columns as a
/// side effect, then fill the full column — which, thanks to that same
/// auto-marking, finishes the whole puzzle without a separate "now mark
/// the rest" step. Auto-marking a satisfied line is real `applyMove`
/// behavior (see `validate_move.dart`), not tutorial-only scripting: two
/// guided fills are genuinely enough to solve this puzzle.
List<TutorialStep> buildTutorialScript() => const [
  TutorialStep(message: TutorialMessage.intro),
  TutorialStep(
    message: TutorialMessage.fillFullRow,
    targetCells: [(2, 0), (2, 1), (2, 2), (2, 3), (2, 4)],
    requiredIntent: CellState.filled,
  ),
  TutorialStep(message: TutorialMessage.autoMarkExplainer),
  TutorialStep(
    message: TutorialMessage.fillFullColumn,
    targetCells: [(0, 2), (1, 2), (3, 2), (4, 2)],
    requiredIntent: CellState.filled,
  ),
];
