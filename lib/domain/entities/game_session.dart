import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';

/// The state of one in-progress (or finished) attempt at a [Puzzle].
///
/// Immutable: every move produces a new `GameSession` via [copyWith] (see
/// `ValidateMove`). Not itself persisted — Isar storage (Phase 3) maps this
/// to/from a save-game model.
class GameSession {
  const GameSession({
    required this.puzzle,
    required this.cellStates,
    required this.heartsRemaining,
    required this.mistakeCount,
    required this.elapsedSeconds,
    required this.won,
    required this.hintsUsed,
    required this.extraHeartUsed,
  });

  factory GameSession.start(Puzzle puzzle, {int startingHearts = 3}) =>
      GameSession(
        puzzle: puzzle,
        cellStates: List<CellState>.filled(
          puzzle.size.cellCount,
          CellState.unknown,
        ),
        heartsRemaining: startingHearts,
        mistakeCount: 0,
        elapsedSeconds: 0,
        won: false,
        hintsUsed: 0,
        extraHeartUsed: false,
      );

  final Puzzle puzzle;

  /// Row-major, length `puzzle.size.cellCount`.
  final List<CellState> cellStates;
  final int heartsRemaining;
  final int mistakeCount;
  final int elapsedSeconds;
  final bool won;

  /// Rewarded hint watches spent this puzzle (Phase 4: capped at
  /// `GameLimits.maxHintsPerPuzzle`).
  final int hintsUsed;

  /// Whether the once-per-puzzle rewarded extra-heart has already been
  /// used (Phase 4: offered once, when hearts hit zero).
  final bool extraHeartUsed;

  int get width => puzzle.size.width;
  int get height => puzzle.size.height;

  bool get outOfHearts => heartsRemaining <= 0;

  /// The session no longer accepts moves: either solved, or out of hearts.
  bool get isOver => won || outOfHearts;

  CellState stateAt(int row, int col) => cellStates[row * width + col];

  /// Whether every solution-filled cell in row [index] is currently
  /// filled — used both to auto-mark a completed row and to dim it in
  /// the board painter. Ignores marks: an unmarked-but-otherwise-correct
  /// row still counts as complete.
  bool isRowComplete(int index) => _lineComplete(isRow: true, index: index);

  /// As [isRowComplete], for a column.
  bool isColumnComplete(int index) => _lineComplete(isRow: false, index: index);

  /// Whether every row matches the solution — the actual win condition.
  bool get isFullySolved {
    for (var r = 0; r < height; r++) {
      if (!isRowComplete(r)) return false;
    }
    return true;
  }

  bool _lineComplete({required bool isRow, required int index}) {
    final length = isRow ? width : height;
    for (var i = 0; i < length; i++) {
      final row = isRow ? index : i;
      final col = isRow ? i : index;
      final shouldFill = puzzle.solution.cellAt(row, col);
      final isFilled = stateAt(row, col) == CellState.filled;
      if (shouldFill != isFilled) return false;
    }
    return true;
  }

  GameSession copyWith({
    List<CellState>? cellStates,
    int? heartsRemaining,
    int? mistakeCount,
    int? elapsedSeconds,
    bool? won,
    int? hintsUsed,
    bool? extraHeartUsed,
  }) => GameSession(
    puzzle: puzzle,
    cellStates: cellStates ?? this.cellStates,
    heartsRemaining: heartsRemaining ?? this.heartsRemaining,
    mistakeCount: mistakeCount ?? this.mistakeCount,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    won: won ?? this.won,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    extraHeartUsed: extraHeartUsed ?? this.extraHeartUsed,
  );
}
