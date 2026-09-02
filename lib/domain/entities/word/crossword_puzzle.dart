import 'package:meta/meta.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';

/// A real, intersecting crossword grid — one numbered link in a
/// `WordPuzzleTrack`'s chain (e.g. "Tarih 3"), same role
/// `WordPuzzleSection` had for the earlier clue-list mechanic. Content is
/// always authored (hand-built or AI-drafted-then-reviewed — see
/// CLAUDE.MD bölüm 6), never generated on-device: fitting intersecting
/// words into a valid grid at runtime is a much harder problem than
/// Nonogram's own solver, and the content pipeline never needed it.
@immutable
class CrosswordPuzzle {
  CrosswordPuzzle({
    required this.trackId,
    required this.sectionIndex,
    required this.width,
    required this.height,
    required this.entries,
  });

  final String trackId;

  /// 1-based position in the track's chain (e.g. 3 for "Tarih 3").
  final int sectionIndex;
  final int width;
  final int height;
  final List<CrosswordEntry> entries;

  /// The solution letter at `(row, col)`, or `null` if that cell is
  /// blocked (not covered by any entry). Precomputed once — the grid is
  /// small, but this is looked up on every keystroke and every repaint.
  late final Map<(int, int), String> _lettersByCell = {
    for (final entry in entries)
      for (var i = 0; i < entry.length; i++) entry.cellAt(i): entry.answer[i],
  };

  String? solutionLetterAt(int row, int col) => _lettersByCell[(row, col)];

  bool isBlocked(int row, int col) => solutionLetterAt(row, col) == null;

  /// The clue number to print in this cell's corner, or `null` if no
  /// entry starts here.
  int? clueNumberAt(int row, int col) {
    for (final entry in entries) {
      if (entry.startRow == row && entry.startCol == col) {
        return entry.clueNumber;
      }
    }
    return null;
  }
}
