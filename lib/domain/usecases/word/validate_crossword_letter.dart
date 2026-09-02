import 'package:nonogram_daily/core/turkish_text.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_puzzle.dart';

/// The outcome of typing one letter into one cell of a [CrosswordPuzzle].
class CellCheckResult {
  const CellCheckResult({required this.correct, required this.updatedLetters});

  /// Whether the typed letter matched the solution at that cell.
  final bool correct;

  /// The letters map as it stands *after* this check — unchanged from
  /// the input when [correct] is `false` (a wrong letter is never
  /// written in; the caller flashes it and clears the cell instead, per
  /// the "no heart cost" mechanic — see CLAUDE.MD).
  final Map<(int, int), String> updatedLetters;
}

/// Checks a single typed letter against [puzzle]'s solution at
/// `(row, col)`. The crossword equivalent of the earlier clue-list
/// mechanic's `validateLetter`, keyed by cell instead of by
/// `(clueId, position)` — an intersecting cell has no single "owning"
/// clue, so checking by cell is what actually matches the mechanic.
CellCheckResult validateCrosswordLetter({
  required CrosswordPuzzle puzzle,
  required Map<(int, int), String> currentLetters,
  required int row,
  required int col,
  required String typedLetter,
}) {
  final expected = puzzle.solutionLetterAt(row, col);
  assert(expected != null, 'validateCrosswordLetter called on a blocked cell');

  final normalizedTyped = toTurkishUpperCase(typedLetter);
  final correct = normalizedTyped == expected;

  if (!correct) {
    return CellCheckResult(correct: false, updatedLetters: currentLetters);
  }

  final updated = Map<(int, int), String>.of(currentLetters);
  updated[(row, col)] = normalizedTyped;
  return CellCheckResult(correct: true, updatedLetters: updated);
}
