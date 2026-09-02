import 'package:meta/meta.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';

/// One numbered link in a `WordPuzzleTrack`'s chain (e.g. "Tarih 3") — a
/// fixed set of [clues] that unlocks once the previous section in that
/// same track is fully solved.
@immutable
class WordPuzzleSection {
  const WordPuzzleSection({
    required this.trackId,
    required this.index,
    required this.clues,
  });

  final String trackId;

  /// 1-based position in the track's chain.
  final int index;
  final List<WordClue> clues;

  /// True once every clue in this section has a solved entry in
  /// [solvedClueIds]. Pure — the caller supplies whatever "solved" set it
  /// tracks (Isar-backed in the real app, in-memory in a test).
  bool isCompleteGiven(Set<String> solvedClueIds) =>
      clues.every((clue) => solvedClueIds.contains(clue.id));
}
