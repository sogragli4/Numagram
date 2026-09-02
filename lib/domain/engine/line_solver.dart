import 'package:nonogram_daily/domain/entities/cell_state.dart';

/// Result of solving a single line. Either every cell's deduced state
/// ([LineSolved]), or a proof that no arrangement of the clue's runs is
/// consistent with the known cells ([LineContradiction]).
sealed class LineSolveResult {
  const LineSolveResult();
}

class LineSolved extends LineSolveResult {
  const LineSolved(this.cells);

  /// The line, same length as the input: known cells unchanged, plus
  /// whatever the solver could newly deduce. Cells that remain ambiguous
  /// across valid placements stay [CellState.unknown].
  final List<CellState> cells;
}

class LineContradiction extends LineSolveResult {
  const LineContradiction();
}

/// Solves one line (a row or column) in isolation.
///
/// Enumerates the legal placements of [clues]' runs that are consistent
/// with [known] — via memoised recursion over `(cellIndex, clueIndex)`,
/// never brute-forcing all `2^n` fill patterns — and intersects them: a
/// cell filled in every legal placement becomes [CellState.filled]; a cell
/// empty in every legal placement becomes [CellState.marked]; otherwise it
/// stays [CellState.unknown].
///
/// Runs in O(n * k) time and space, where n = `known.length` and
/// k = `clues.length`.
LineSolveResult solveLine(List<int> clues, List<CellState> known) {
  final n = known.length;
  final k = clues.length;

  // feasible[i][j]: can clues[j:] be placed within known[i:n], consistent
  // with the already-known cells? null = not yet computed.
  final memo = List.generate(n + 1, (_) => List<bool?>.filled(k + 1, null));

  bool canPlaceRun(int start, int len) {
    if (start + len > n) return false;
    for (var idx = start; idx < start + len; idx++) {
      if (known[idx] == CellState.marked) return false;
    }
    return true;
  }

  bool feasible(int i, int j) {
    final cached = memo[i][j];
    if (cached != null) return cached;

    bool result;
    if (j == k) {
      result = true;
      for (var idx = i; idx < n; idx++) {
        if (known[idx] == CellState.filled) {
          result = false;
          break;
        }
      }
    } else if (i >= n) {
      result = false;
    } else {
      result = false;
      if (known[i] != CellState.filled && feasible(i + 1, j)) {
        result = true;
      }
      if (!result) {
        final len = clues[j];
        if (canPlaceRun(i, len)) {
          final after = i + len;
          if (after == n) {
            result = feasible(after, j + 1);
          } else if (known[after] != CellState.filled) {
            result = feasible(after + 1, j + 1);
          }
        }
      }
    }
    memo[i][j] = result;
    return result;
  }

  if (!feasible(0, 0)) return const LineContradiction();

  final canBeFilled = List<bool>.filled(n, false);
  final canBeEmpty = List<bool>.filled(n, false);

  // Walk the state graph of (cellIndex, clueIndex) pairs reachable from the
  // start, following only transitions that lead to a feasible completion.
  // Each state has at most 2 outgoing transitions, so this is O(n * k)
  // despite the number of *paths* (full placements) potentially being much
  // larger — we visit each state once, not each placement.
  final visited = <int>{};
  final stack = <(int, int)>[(0, 0)];
  while (stack.isNotEmpty) {
    final (i, j) = stack.removeLast();
    if (!visited.add(i * (k + 1) + j)) continue;

    if (j == k) {
      for (var idx = i; idx < n; idx++) {
        canBeEmpty[idx] = true;
      }
      continue;
    }
    if (i >= n) continue;

    if (known[i] != CellState.filled && feasible(i + 1, j)) {
      canBeEmpty[i] = true;
      stack.add((i + 1, j));
    }

    final len = clues[j];
    if (canPlaceRun(i, len)) {
      final after = i + len;
      if (after == n) {
        if (feasible(after, j + 1)) {
          for (var idx = i; idx < after; idx++) {
            canBeFilled[idx] = true;
          }
          stack.add((after, j + 1));
        }
      } else if (known[after] != CellState.filled &&
          feasible(after + 1, j + 1)) {
        for (var idx = i; idx < after; idx++) {
          canBeFilled[idx] = true;
        }
        // The cell immediately after the run is a mandatory gap in this
        // placement (it is not itself part of the next run's placement
        // decision — that starts at `after + 1`), so it must be recorded
        // as empty here or this branch's constraint on it is lost.
        canBeEmpty[after] = true;
        stack.add((after + 1, j + 1));
      }
    }
  }

  final result = List<CellState>.generate(n, (idx) {
    if (known[idx] != CellState.unknown) return known[idx];
    final canFill = canBeFilled[idx];
    final canEmpty = canBeEmpty[idx];
    if (canFill && !canEmpty) return CellState.filled;
    if (canEmpty && !canFill) return CellState.marked;
    return CellState.unknown;
  });

  return LineSolved(result);
}
