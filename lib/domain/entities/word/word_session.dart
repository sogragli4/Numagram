import 'package:meta/meta.dart';
import 'package:nonogram_daily/domain/entities/word/word_puzzle_section.dart';

/// Play-in-progress state for one [WordPuzzleSection]: the letters typed
/// so far for every clue in it. The word-puzzle equivalent of
/// `GameSession`, minus anything heart/mistake-related — see
/// CLAUDE.MD's "no heart cost" decision for why that doesn't carry over.
@immutable
class WordSession {
  const WordSession({required this.section, required this.lettersByClueId});

  /// One fresh, all-empty session for [section].
  factory WordSession.start(WordPuzzleSection section) => WordSession(
    section: section,
    lettersByClueId: {
      for (final clue in section.clues)
        clue.id: List<String?>.filled(clue.length, null),
    },
  );

  final WordPuzzleSection section;

  /// Current letters per clue id — one entry per answer position, `null`
  /// where still empty. Always has exactly one key per clue in [section].
  final Map<String, List<String?>> lettersByClueId;

  /// Clue ids whose every letter position is filled.
  Set<String> get solvedClueIds => {
    for (final entry in lettersByClueId.entries)
      if (entry.value.every((letter) => letter != null)) entry.key,
  };

  /// True once every clue in [section] is solved.
  bool get won => section.isCompleteGiven(solvedClueIds);

  WordSession copyWith({Map<String, List<String?>>? lettersByClueId}) =>
      WordSession(
        section: section,
        lettersByClueId: lettersByClueId ?? this.lettersByClueId,
      );
}
