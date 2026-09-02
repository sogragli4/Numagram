import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/domain/entities/puzzle.dart';
import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';
import 'package:nonogram_daily/domain/usecases/use_hint.dart';
import 'package:nonogram_daily/domain/usecases/validate_move.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:nonogram_daily/services/ads/ad_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'board_controller.g.dart';

/// How a drag-paint stroke stays locked to one row or column once
/// movement has started, per the Phase 2 spec.
enum PaintAxis { none, row, column }

const int _maxUndoDepth = 50;

/// Which puzzle [BoardController] plays and, if it's a daily/archive
/// puzzle, what date to record a win against.
@immutable
class BoardArgs {
  const BoardArgs.daily({required this.puzzle, required this.date})
    : isDaily = true;

  const BoardArgs.freePlay({required this.puzzle})
    : isDaily = false,
      date = null;

  final Puzzle puzzle;
  final bool isDaily;
  final DateTime? date;

  String get analyticsSource {
    if (!isDaily) return 'free_play';
    // Today's daily puzzle vs. a past date opened from the archive are
    // the same feature under the hood (see ArchiveScreen) but worth
    // telling apart in Analytics.
    final today = DateTime.now();
    final isToday =
        date!.year == today.year &&
        date!.month == today.month &&
        date!.day == today.day;
    return isToday ? 'daily' : 'archive';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardArgs &&
          identical(puzzle, other.puzzle) &&
          isDaily == other.isDaily &&
          date == other.date);

  @override
  int get hashCode => Object.hash(identityHashCode(puzzle), isDaily, date);
}

class BoardState {
  const BoardState({
    required this.session,
    required this.mode,
    required this.paintAxis,
    required this.paintFixedIndex,
    required this.lastPaintedRow,
    required this.lastPaintedCol,
    required this.wrongFlashRow,
    required this.wrongFlashCol,
    required this.wrongFlashToken,
    required this.canUndo,
    required this.focusedRow,
    required this.hintInFlight,
  });

  final GameSession session;

  /// The player's current tool: [CellState.filled] or [CellState.marked].
  final CellState mode;

  final PaintAxis paintAxis;
  final int? paintFixedIndex;
  final int? lastPaintedRow;
  final int? lastPaintedCol;

  /// The most recent wrong-fill cell, plus a token that increments on
  /// every wrong fill so the UI can restart the flash animation even if
  /// the same cell is tapped wrongly twice in a row.
  final int? wrongFlashRow;
  final int? wrongFlashCol;
  final int wrongFlashToken;

  final bool canUndo;

  /// The row a hint watch would reveal a cell in — the last row the
  /// player tapped or painted in, per the Phase 4 spec's "currently
  /// focused line".
  final int focusedRow;

  /// True while a rewarded-ad watch is in progress, so the UI can disable
  /// the hint/extra-heart buttons rather than let the player double-tap.
  final bool hintInFlight;

  BoardState copyWith({
    GameSession? session,
    CellState? mode,
    PaintAxis? paintAxis,
    int? Function()? paintFixedIndex,
    int? Function()? lastPaintedRow,
    int? Function()? lastPaintedCol,
    int? Function()? wrongFlashRow,
    int? Function()? wrongFlashCol,
    int? wrongFlashToken,
    bool? canUndo,
    int? focusedRow,
    bool? hintInFlight,
  }) => BoardState(
    session: session ?? this.session,
    mode: mode ?? this.mode,
    paintAxis: paintAxis ?? this.paintAxis,
    paintFixedIndex: paintFixedIndex != null
        ? paintFixedIndex()
        : this.paintFixedIndex,
    lastPaintedRow: lastPaintedRow != null
        ? lastPaintedRow()
        : this.lastPaintedRow,
    lastPaintedCol: lastPaintedCol != null
        ? lastPaintedCol()
        : this.lastPaintedCol,
    wrongFlashRow: wrongFlashRow != null ? wrongFlashRow() : this.wrongFlashRow,
    wrongFlashCol: wrongFlashCol != null ? wrongFlashCol() : this.wrongFlashCol,
    wrongFlashToken: wrongFlashToken ?? this.wrongFlashToken,
    canUndo: canUndo ?? this.canUndo,
    focusedRow: focusedRow ?? this.focusedRow,
    hintInFlight: hintInFlight ?? this.hintInFlight,
  );
}

@riverpod
class BoardController extends _$BoardController {
  final List<GameSession> _undoStack = [];
  Timer? _ticker;
  late BoardArgs _args;

  @override
  BoardState build(BoardArgs args) {
    _args = args;
    final session = GameSession.start(args.puzzle);

    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logPuzzleStarted(
            source: args.analyticsSource,
            width: args.puzzle.size.width,
            height: args.puzzle.size.height,
          ),
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.session.isOver) return;
      state = state.copyWith(
        session: state.session.copyWith(
          elapsedSeconds: state.session.elapsedSeconds + 1,
        ),
      );
    });
    ref.onDispose(() => _ticker?.cancel());

    return BoardState(
      session: session,
      mode: CellState.filled,
      paintAxis: PaintAxis.none,
      paintFixedIndex: null,
      lastPaintedRow: null,
      lastPaintedCol: null,
      wrongFlashRow: null,
      wrongFlashCol: null,
      wrongFlashToken: 0,
      canUndo: false,
      focusedRow: 0,
      hintInFlight: false,
    );
  }

  void toggleMode() {
    final next = state.mode == CellState.filled
        ? CellState.marked
        : CellState.filled;
    state = state.copyWith(mode: next);
  }

  /// A single tap: one full move, one undo entry.
  void tapCell(int row, int col) {
    if (state.session.isOver) return;
    _pushUndo();
    state = state.copyWith(focusedRow: row);
    _applyAndCommit(row, col, state.mode);
  }

  /// Begins a long-press-drag paint stroke. The whole stroke — however
  /// many cells it ends up touching — is one undo entry.
  void startPaintStroke(int row, int col) {
    if (state.session.isOver) return;
    _pushUndo();
    state = state.copyWith(
      paintAxis: PaintAxis.none,
      lastPaintedRow: () => row,
      lastPaintedCol: () => col,
      focusedRow: row,
    );
    _paintCellIfNeeded(row, col);
  }

  /// Continues a stroke toward `(row, col)`, locking to whichever axis the
  /// drag first moved along and painting every cell in between so a fast
  /// drag doesn't skip cells.
  void continuePaintStroke(int row, int col) {
    if (state.session.isOver) return;
    final startRow = state.lastPaintedRow;
    final startCol = state.lastPaintedCol;
    if (startRow == null || startCol == null) return;

    var axis = state.paintAxis;
    if (axis == PaintAxis.none) {
      final dRow = (row - startRow).abs();
      final dCol = (col - startCol).abs();
      if (dRow == 0 && dCol == 0) return;
      axis = dCol >= dRow ? PaintAxis.row : PaintAxis.column;
      state = state.copyWith(
        paintAxis: axis,
        paintFixedIndex: () => axis == PaintAxis.row ? startRow : startCol,
      );
    }

    if (axis == PaintAxis.row) {
      final fixedRow = state.paintFixedIndex ?? startRow;
      _paintRange(fixedRow, startCol, col, alongRow: true);
      state = state.copyWith(lastPaintedCol: () => col);
    } else {
      final fixedCol = state.paintFixedIndex ?? startCol;
      _paintRange(fixedCol, startRow, row, alongRow: false);
      state = state.copyWith(lastPaintedRow: () => row);
    }
  }

  void endPaintStroke() {
    state = state.copyWith(
      paintAxis: PaintAxis.none,
      paintFixedIndex: () => null,
      lastPaintedRow: () => null,
      lastPaintedCol: () => null,
    );
  }

  /// Starts the same puzzle over from scratch — offered after the player
  /// runs out of hearts and declines (or has already used) the rewarded
  /// extra heart.
  void restart() {
    _undoStack.clear();
    state = state.copyWith(
      session: GameSession.start(state.session.puzzle),
      canUndo: false,
      wrongFlashRow: () => null,
      wrongFlashCol: () => null,
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    state = state.copyWith(session: previous, canUndo: _undoStack.isNotEmpty);
  }

  /// Watches a rewarded ad and, if the player earns the reward, reveals
  /// one cell in [BoardState.focusedRow] (Phase 4: capped at
  /// `GameLimits.maxHintsPerPuzzle`).
  Future<void> requestHint() async {
    if (!FeatureFlags.hintRewardedAdEnabled) return;
    if (state.hintInFlight || state.session.isOver) return;
    if (state.session.hintsUsed >= GameLimits.maxHintsPerPuzzle) return;

    state = state.copyWith(hintInFlight: true);
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.logRewardedShown(placement: 'hint');
    final earned = await ref
        .read(adServiceProvider)
        .showRewarded(RewardedPlacement.hint);
    if (earned) {
      await analytics.logRewardedCompleted(placement: 'hint');
      final result = useHint(
        session: state.session,
        focusRow: state.focusedRow,
      );
      if (result.hintApplied) {
        await analytics.logHintUsed();
        state = state.copyWith(session: result.session);
      }
    }
    state = state.copyWith(hintInFlight: false);
  }

  /// Watches a rewarded ad and, if earned, grants the once-per-puzzle
  /// extra heart so the player can keep going instead of failing out.
  Future<void> requestExtraHeart() async {
    if (!FeatureFlags.extraHeartRewardedAdEnabled) return;
    if (state.hintInFlight || state.session.extraHeartUsed) return;
    if (!state.session.outOfHearts) return;

    state = state.copyWith(hintInFlight: true);
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.logRewardedShown(placement: 'extra_heart');
    final earned = await ref
        .read(adServiceProvider)
        .showRewarded(RewardedPlacement.extraHeart);
    if (earned) {
      await analytics.logRewardedCompleted(placement: 'extra_heart');
      state = state.copyWith(
        session: state.session.copyWith(
          heartsRemaining: 1,
          extraHeartUsed: true,
        ),
      );
    }
    state = state.copyWith(hintInFlight: false);
  }

  void _paintRange(int fixed, int from, int to, {required bool alongRow}) {
    final lo = from < to ? from : to;
    final hi = from < to ? to : from;
    for (var i = lo; i <= hi; i++) {
      if (alongRow) {
        _paintCellIfNeeded(fixed, i);
      } else {
        _paintCellIfNeeded(i, fixed);
      }
    }
  }

  /// Paints one cell during a stroke, uniformly toward [BoardState.mode] —
  /// a stroke only ever *adds* fills/marks, it never un-paints a cell it
  /// passes back over, so re-entering already-painted cells is harmless.
  void _paintCellIfNeeded(int row, int col) {
    final already = state.session.stateAt(row, col) == state.mode;
    if (already) return;
    _applyAndCommit(row, col, state.mode);
  }

  void _applyAndCommit(int row, int col, CellState intent) {
    final wasWon = state.session.won;
    final result = applyMove(
      session: state.session,
      row: row,
      col: col,
      intent: intent,
    );

    state = state.copyWith(
      session: result.session,
      canUndo: _undoStack.isNotEmpty,
      wrongFlashRow: result.wasWrongFill ? () => row : () => null,
      wrongFlashCol: result.wasWrongFill ? () => col : () => null,
      wrongFlashToken: result.wasWrongFill
          ? state.wrongFlashToken + 1
          : state.wrongFlashToken,
    );

    if (result.wasWrongFill) {
      unawaited(HapticFeedback.heavyImpact());
    } else if (intent == CellState.marked) {
      unawaited(HapticFeedback.selectionClick());
    } else {
      unawaited(HapticFeedback.lightImpact());
    }
    if (!wasWon && result.session.won) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(_onWin(result.session));
    }
  }

  /// Records every win — daily/archive *and* free play — so the
  /// statistics screen's totals reflect all play, not just the daily
  /// puzzle. Only a non-null [BoardArgs.date] (daily/archive) counts
  /// toward the streak; [PuzzleCompletion.date] carries that through.
  /// Free play additionally feeds the interstitial frequency gate.
  Future<void> _onWin(GameSession session) async {
    final analytics = ref.read(analyticsServiceProvider);
    unawaited(
      analytics.logPuzzleCompleted(
        source: _args.analyticsSource,
        elapsedSeconds: session.elapsedSeconds,
        perfect: session.mistakeCount == 0,
      ),
    );

    final completion = PuzzleCompletion(
      date: _args.date,
      size: session.puzzle.size,
      difficulty: session.puzzle.difficulty,
      elapsedSeconds: session.elapsedSeconds,
      mistakeCount: session.mistakeCount,
      completedAt: DateTime.now(),
    );
    await ref
        .read(updateStreakProvider)
        .call(completion: completion, today: DateTime.now());

    if (!_args.isDaily) {
      await _maybeShowInterstitial();
    }
  }

  Future<void> _maybeShowInterstitial() async {
    final gate = ref.read(interstitialGateProvider)..recordFreePlayCompletion();

    final settings = ref.read(appSettingsControllerProvider);
    final eligible = gate.isEligible(
      isFreePlay: true,
      sessionCount: settings.sessionCount,
      hasCompletedFirstPuzzleEver: settings.hasCompletedFirstPuzzle,
    );
    if (!eligible) return;

    final shown = await ref.read(adServiceProvider).showInterstitial();
    if (shown) {
      gate.recordShown();
      unawaited(ref.read(analyticsServiceProvider).logInterstitialShown());
    }
  }

  void _pushUndo() {
    _undoStack.add(state.session);
    if (_undoStack.length > _maxUndoDepth) {
      _undoStack.removeAt(0);
    }
  }
}
