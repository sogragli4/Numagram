import 'package:flutter/material.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/puzzle_grid.dart';
import 'package:nonogram_daily/presentation/game/share_card.dart';

/// The "you solved it" bottom sheet: time, hearts left, and a shareable
/// card of the solved grid, per the Phase 2/5 specs.
Future<void> showCompletionSheet(
  BuildContext context, {
  required Duration elapsed,
  required int heartsRemaining,
  required PuzzleGrid solution,
  required DateTime date,
}) {
  final l10n = AppLocalizations.of(context);
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  final elapsedLabel = '$minutes:$seconds';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.puzzleCompletedTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(l10n.timeLabel),
                    Text(
                      elapsedLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(l10n.heartsRemaining(heartsRemaining)),
                    Text(
                      '$heartsRemaining',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ShareSection(
              solution: solution,
              elapsedLabel: elapsedLabel,
              date: date,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.continueButtonLabel),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Hosts the real, laid-out [ShareCard] (needed so its [RepaintBoundary]
/// has something to capture) and the button that triggers the OS share
/// sheet from it.
class _ShareSection extends StatefulWidget {
  const _ShareSection({
    required this.solution,
    required this.elapsedLabel,
    required this.date,
  });

  final PuzzleGrid solution;
  final String elapsedLabel;
  final DateTime date;

  @override
  State<_ShareSection> createState() => _ShareSectionState();
}

class _ShareSectionState extends State<_ShareSection> {
  final GlobalKey _boundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: ShareCard(
            solution: widget.solution,
            elapsedLabel: widget.elapsedLabel,
            dateLabel: formatShareCardDate(context, widget.date),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => shareCompletionCard(
            boundaryKey: _boundaryKey,
            shareText: l10n.shareCardMessage(widget.elapsedLabel),
          ),
          icon: const Icon(Icons.share),
          label: Text(l10n.shareButtonLabel),
        ),
      ],
    );
  }
}
