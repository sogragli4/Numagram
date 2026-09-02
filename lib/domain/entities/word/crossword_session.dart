import 'package:meta/meta.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_puzzle.dart';

/// Play-in-progress state for one [CrosswordPuzzle]: the letters typed so
/// far, keyed by cell — not by entry, since an intersecting cell belongs
/// to both an across and a down entry at once, and a single typed letter
/// there satisfies both.
@immutable
class CrosswordSession {
  const CrosswordSession({required this.puzzle, required this.typedLetters});

  factory CrosswordSession.start(CrosswordPuzzle puzzle) =>
      CrosswordSession(puzzle: puzzle, typedLetters: const {});

  final CrosswordPuzzle puzzle;

  /// Only ever holds *correct* letters — a wrong guess is never written
  /// in (see `validateCrosswordLetter`), so there is nothing to roll back
  /// before the caller shows its flash-and-clear feedback.
  final Map<(int, int), String> typedLetters;

  bool isEntrySolved(CrosswordEntry entry) {
    for (var i = 0; i < entry.length; i++) {
      if (typedLetters[entry.cellAt(i)] == null) return false;
    }
    return true;
  }

  /// True once every entry (equivalently, every non-blocked cell) is
  /// filled.
  bool get won => puzzle.entries.every(isEntrySolved);

  CrosswordSession copyWith({Map<(int, int), String>? typedLetters}) =>
      CrosswordSession(
        puzzle: puzzle,
        typedLetters: typedLetters ?? this.typedLetters,
      );
}
