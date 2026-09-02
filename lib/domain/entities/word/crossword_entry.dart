import 'package:meta/meta.dart';
import 'package:nonogram_daily/core/turkish_text.dart';

enum CrosswordDirection { across, down }

/// One word placed in a `CrosswordPuzzle`'s grid — e.g. 1-Across, "Sayfalardan
/// oluşan okuma malzemesi" → KİTAP. Several entries can share a cell (an
/// intersection); `CrosswordPuzzle` is what reconciles that, not this class.
@immutable
class CrosswordEntry {
  CrosswordEntry({
    required this.id,
    required this.clueNumber,
    required this.direction,
    required this.startRow,
    required this.startCol,
    required this.clueText,
    required String answer,
  }) : answer = toTurkishUpperCase(answer);

  final String id;

  /// The number printed in the grid corner where this entry starts —
  /// shared with any other entry starting at the same cell (standard
  /// crossword numbering).
  final int clueNumber;
  final CrosswordDirection direction;
  final int startRow;
  final int startCol;
  final String clueText;
  final String answer;

  int get length => answer.length;

  /// The `(row, col)` of the [position]-th letter of this entry.
  (int, int) cellAt(int position) => direction == CrosswordDirection.across
      ? (startRow, startCol + position)
      : (startRow + position, startCol);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrosswordEntry &&
          id == other.id &&
          clueNumber == other.clueNumber &&
          direction == other.direction &&
          startRow == other.startRow &&
          startCol == other.startCol &&
          clueText == other.clueText &&
          answer == other.answer);

  @override
  int get hashCode => Object.hash(
    id,
    clueNumber,
    direction,
    startRow,
    startCol,
    clueText,
    answer,
  );
}
