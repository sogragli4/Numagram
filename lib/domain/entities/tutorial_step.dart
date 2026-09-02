import 'package:meta/meta.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';

/// Which coaching message a [TutorialStep] shows — resolved to localized
/// text in the presentation layer, since domain entities don't hold
/// localized strings themselves.
enum TutorialMessage { intro, fillFullRow, autoMarkExplainer, fillFullColumn }

/// One step of the interactive tutorial.
///
/// A step with an empty [targetCells] (the intro and the auto-mark
/// explainer) advances only when the player taps "Continue". A step with
/// [targetCells] advances once every listed cell has been set to
/// [requiredIntent].
@immutable
class TutorialStep {
  const TutorialStep({
    required this.message,
    this.targetCells = const [],
    this.requiredIntent,
  });

  final TutorialMessage message;

  /// `(row, col)` cells the player must set to [requiredIntent] before
  /// this step is complete.
  final List<(int, int)> targetCells;

  final CellState? requiredIntent;
}
