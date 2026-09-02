/// State of a single cell during play or solving.
///
/// Distinct from the boolean solution stored in `PuzzleGrid`: a puzzle in
/// progress (or mid-solve) has cells that are not yet known either way.
enum CellState {
  /// Not yet determined.
  unknown,

  /// Deduced or played as part of the solution.
  filled,

  /// Deduced or played as definitely not part of the solution (the
  /// player's X mark).
  marked,
}
