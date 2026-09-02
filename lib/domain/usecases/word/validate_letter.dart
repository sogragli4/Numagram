import 'package:nonogram_daily/core/turkish_text.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';

/// The outcome of typing one letter into one position of a [WordClue]'s
/// answer.
class LetterCheckResult {
  const LetterCheckResult({
    required this.correct,
    required this.updatedLetters,
    required this.clueSolved,
  });

  /// Whether the typed letter matched the answer at that position.
  final bool correct;

  /// The letters array as it stands *after* this check — unchanged from
  /// the input when [correct] is `false` (a wrong letter is never
  /// written in; the caller flashes it and clears the box instead, per
  /// the "no heart cost" mechanic — see CLAUDE.MD).
  final List<String?> updatedLetters;

  /// True once every position in [updatedLetters] is filled.
  final bool clueSolved;
}

/// Checks a single typed letter against [clue]'s answer at [position].
/// [currentLetters] is one entry per answer position (`null` = still
/// empty) — the word-puzzle equivalent of nonogram's `applyMove`, but
/// per-letter and with no mistake/heart cost: a wrong letter simply isn't
/// written into the result, so the caller can revert the box to empty
/// after showing the flash.
LetterCheckResult validateLetter({
  required WordClue clue,
  required List<String?> currentLetters,
  required int position,
  required String typedLetter,
}) {
  assert(
    currentLetters.length == clue.length,
    'currentLetters must have one entry per answer position',
  );

  final expected = clue.answer[position];
  final normalizedTyped = toTurkishUpperCase(typedLetter);
  final correct = normalizedTyped == expected;

  if (!correct) {
    return LetterCheckResult(
      correct: false,
      updatedLetters: currentLetters,
      clueSolved: false,
    );
  }

  final updated = List<String?>.of(currentLetters);
  updated[position] = normalizedTyped;
  final solved = updated.every((letter) => letter != null);

  return LetterCheckResult(
    correct: true,
    updatedLetters: updated,
    clueSolved: solved,
  );
}
