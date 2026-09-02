import 'package:meta/meta.dart';

/// The run-length clue for a single row or column: the length of each
/// consecutive block of filled cells, in order. An empty line has `runs`
/// equal to `[]` (not `[0]`).
@immutable
class LineClue {
  const LineClue(this.runs);

  /// Derives the clue from a line's actual cell values.
  factory LineClue.fromCells(List<bool> cells) {
    final runs = <int>[];
    var current = 0;
    for (final filled in cells) {
      if (filled) {
        current++;
      } else if (current > 0) {
        runs.add(current);
        current = 0;
      }
    }
    if (current > 0) runs.add(current);
    return LineClue(runs);
  }

  final List<int> runs;

  /// The minimum line length that could satisfy this clue: every run plus
  /// one mandatory gap between consecutive runs.
  int get minimumLineLength {
    if (runs.isEmpty) return 0;
    return runs.reduce((a, b) => a + b) + runs.length - 1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LineClue) return false;
    if (runs.length != other.runs.length) return false;
    for (var i = 0; i < runs.length; i++) {
      if (runs[i] != other.runs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(runs);

  @override
  String toString() => runs.isEmpty ? '(none)' : runs.join(' ');
}
