import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/free_play_size_preset.dart';
import 'package:nonogram_daily/presentation/daily/daily_controller.dart';
import 'package:nonogram_daily/presentation/game/board_controller.dart';
import 'package:nonogram_daily/presentation/game/board_screen.dart';

/// Pick a grid size, then play an endless, randomly-seeded puzzle at that
/// size. True difficulty (easy/medium/hard) is a property of the specific
/// generated puzzle, not something the player dials in directly — size is
/// the input, difficulty is shown once the puzzle is generated.
///
/// The largest size is a streak-milestone unlock (see
/// `FreePlaySizePreset`/`FreePlaySizeUnlocks`) — personal progression,
/// unlike the daily puzzle's day-of-week size rhythm (`dailySizeForDate`),
/// which stays the same for every player on a given date.
class FreePlayScreen extends ConsumerStatefulWidget {
  const FreePlayScreen({super.key});

  @override
  ConsumerState<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends ConsumerState<FreePlayScreen> {
  int _selectedIndex = 1;
  bool _generating = false;

  Future<void> _play() async {
    setState(() => _generating = true);
    final preset = freePlaySizePresets[_selectedIndex];
    final puzzle = await ref
        .read(puzzleRepositoryProvider)
        .getFreePlayPuzzle(width: preset.width, height: preset.height);
    if (!mounted) return;
    setState(() => _generating = false);

    // The generator can fall back to a smaller size when it can't find a
    // uniquely-solvable puzzle at the requested one within its attempt
    // budget (see `generatePuzzle`) — most likely at the 20x20 tier, where
    // the "Go Big" achievement lives. Silently handing the player a
    // different-sized puzzle than the one they picked, with no
    // indication, would make that achievement look unreachable for no
    // visible reason.
    if (puzzle.size.width != preset.width ||
        puzzle.size.height != preset.height) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.freePlaySizeFallbackNotice(
              preset.width,
              preset.height,
              puzzle.size.width,
              puzzle.size.height,
            ),
          ),
        ),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(args: BoardArgs.freePlay(puzzle: puzzle)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final longestStreak =
        ref.watch(streakForTodayProvider).value?.longestStreak ?? 0;
    final labels = [
      l10n.freePlaySizeSmall,
      l10n.freePlaySizeMedium,
      l10n.freePlaySizeLarge,
      l10n.freePlaySizeExtraLarge,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.freePlayTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.freePlaySizeLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: [
                for (final (i, preset) in freePlaySizePresets.indexed)
                  ButtonSegment(
                    value: i,
                    enabled: preset.isUnlockedAt(longestStreak),
                    icon: preset.isUnlockedAt(longestStreak)
                        ? null
                        : const Icon(Icons.lock, size: 16),
                    label: Text(
                      '${labels[i]} (${preset.width}×${preset.height})',
                    ),
                  ),
              ],
              selected: {_selectedIndex},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedIndex = selection.first),
            ),
            if (!freePlaySizePresets.last.isUnlockedAt(longestStreak)) ...[
              const SizedBox(height: 8),
              Text(
                l10n.themeLockedHint(freePlaySizePresets.last.requiredStreak),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _generating ? null : _play,
                child: _generating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.playButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
