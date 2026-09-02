import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/core/theme.dart';
import 'package:nonogram_daily/domain/entities/tutorial_step.dart';
import 'package:nonogram_daily/presentation/game/board_layout.dart';
import 'package:nonogram_daily/presentation/game/board_painter.dart';
import 'package:nonogram_daily/presentation/onboarding/tutorial_controller.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';

/// The interactive "how to play" tutorial: a fixed, guided puzzle that
/// teaches nonogram logic by having the player apply it themselves,
/// through [TutorialController] and the same [BoardPainter] the real
/// board uses. Shown automatically before the player's first-ever puzzle
/// (see the router in `main.dart`) and replayable from Settings.
class TutorialScreen extends ConsumerWidget {
  const TutorialScreen({super.key});

  Future<void> _exit(BuildContext context, WidgetRef ref) async {
    await ref.read(appSettingsControllerProvider.notifier).markTutorialSeen();
    // Pops back to Settings when replayed from there; a no-op at the app
    // root, where the settings change just made above makes the home
    // router swap this screen for `DailyScreen` on its own.
    if (context.mounted) await Navigator.of(context).maybePop();
  }

  String _messageFor(AppLocalizations l10n, TutorialMessage message) =>
      switch (message) {
        TutorialMessage.intro => l10n.tutorialIntroMessage,
        TutorialMessage.fillFullRow => l10n.tutorialFillFullRowMessage,
        TutorialMessage.autoMarkExplainer =>
          l10n.tutorialAutoMarkExplainerMessage,
        TutorialMessage.fillFullColumn => l10n.tutorialFillFullColumnMessage,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(tutorialControllerProvider);
    final controller = ref.read(tutorialControllerProvider.notifier);

    if (state.finished) {
      return _FinishedView(onContinue: () => _exit(context, ref));
    }

    final session = state.session;
    final colorScheme = Theme.of(context).colorScheme;
    final layout = BoardLayout(
      puzzleWidth: session.width,
      puzzleHeight: session.height,
      rowClues: session.puzzle.rowClues,
      columnClues: session.puzzle.columnClues,
    );
    final step = state.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.tutorialStepProgress(state.stepIndex + 1, state.stepCount),
        ),
        actions: [
          TextButton(
            onPressed: () => _exit(context, ref),
            child: Text(l10n.tutorialSkipButtonLabel),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTapUp: (details) {
                  final cell = layout.cellAt(details.localPosition);
                  if (cell != null) controller.tapCell(cell.$1, cell.$2);
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: layout.totalSize,
                    painter: BoardPainter(
                      session: session,
                      layout: layout,
                      palette: BoardPalette.standard,
                      gridLineColor: colorScheme.outlineVariant,
                      textColor: colorScheme.onSurface,
                      backgroundColor: colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_messageFor(l10n, step.message)),
                      if (step.targetCells.isEmpty) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: controller.continueStep,
                          child: Text(l10n.continueButtonLabel),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tutorialFinishedTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(l10n.tutorialFinishedMessage, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onContinue,
                  child: Text(l10n.tutorialStartPlayingButtonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
