import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/domain/entities/tutorial_step.dart';
import 'package:nonogram_daily/domain/usecases/tutorial_script.dart';
import 'package:nonogram_daily/domain/usecases/validate_move.dart';
import 'package:nonogram_daily/presentation/shared/sound_gate.dart';
import 'package:nonogram_daily/services/sound/sound_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tutorial_controller.g.dart';

class TutorialState {
  const TutorialState({
    required this.session,
    required this.stepIndex,
    required this.stepCount,
    required this.currentStep,
    required this.finished,
  });

  final GameSession session;
  final int stepIndex;
  final int stepCount;
  final TutorialStep currentStep;

  /// True once every scripted step is complete.
  final bool finished;

  TutorialState copyWith({
    GameSession? session,
    int? stepIndex,
    TutorialStep? currentStep,
    bool? finished,
  }) => TutorialState(
    session: session ?? this.session,
    stepIndex: stepIndex ?? this.stepIndex,
    stepCount: stepCount,
    currentStep: currentStep ?? this.currentStep,
    finished: finished ?? this.finished,
  );
}

/// Drives the fixed [buildTutorialPuzzle] through [buildTutorialScript]'s
/// steps, via the real gameplay engine (`applyMove`, `GameSession`) so
/// what's taught matches how the real board actually behaves — including
/// its real auto-mark behavior, which is what finishes this puzzle after
/// the second guided fill (see `buildTutorialScript`'s doc comment).
///
/// Every target cell in the script is, by construction (see
/// `tutorial_script_test.dart`), part of the solution, so a tap on one
/// always succeeds — there's no wrong-fill/heart-loss path to handle
/// here, unlike the real board.
@riverpod
class TutorialController extends _$TutorialController {
  static final List<TutorialStep> _script = buildTutorialScript();

  @override
  TutorialState build() {
    final puzzle = buildTutorialPuzzle();
    return TutorialState(
      session: GameSession.start(puzzle),
      stepIndex: 0,
      stepCount: _script.length,
      currentStep: _script.first,
      finished: false,
    );
  }

  /// Advances past a step with no target cells (the intro and the
  /// auto-mark explainer) — a no-op for a step with target cells, which
  /// advances on its own once every target is satisfied.
  void continueStep() {
    if (state.currentStep.targetCells.isNotEmpty) return;
    _advanceStep();
  }

  void tapCell(int row, int col) {
    if (state.finished) return;
    final step = state.currentStep;
    if (!step.targetCells.contains((row, col))) return;

    // A cell already at the step's required state (e.g. a double-tap on
    // an already-correctly-filled target) must be a no-op — `applyMove`
    // treats a tap on an already-filled cell as an *undo*, which would
    // silently erase progress a player just made. Same guard
    // `BoardController._paintCellIfNeeded` uses for the same reason.
    if (state.session.stateAt(row, col) == step.requiredIntent) return;

    final result = applyMove(
      session: state.session,
      row: row,
      col: col,
      intent: step.requiredIntent!,
    );
    state = state.copyWith(session: result.session);
    unawaited(HapticFeedback.lightImpact());
    unawaited(playSoundIfEnabled(ref, SoundEffect.fill));

    final allTargetsMet = step.targetCells.every(
      (cell) => state.session.stateAt(cell.$1, cell.$2) == step.requiredIntent,
    );
    if (allTargetsMet) _advanceStep();
  }

  void _advanceStep() {
    final next = state.stepIndex + 1;
    if (next >= _script.length) {
      state = state.copyWith(finished: true);
      return;
    }
    state = state.copyWith(stepIndex: next, currentStep: _script[next]);
  }
}
