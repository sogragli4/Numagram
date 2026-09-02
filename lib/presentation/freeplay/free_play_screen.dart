import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/presentation/game/board_controller.dart';
import 'package:nonogram_daily/presentation/game/board_screen.dart';

class _SizePreset {
  const _SizePreset(this.width, this.height);
  final int width;
  final int height;
}

const _presets = [_SizePreset(5, 5), _SizePreset(10, 10), _SizePreset(15, 15)];

/// Pick a grid size, then play an endless, randomly-seeded puzzle at that
/// size. True difficulty (easy/medium/hard) is a property of the specific
/// generated puzzle, not something the player dials in directly — size is
/// the input, difficulty is shown once the puzzle is generated.
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
    final preset = _presets[_selectedIndex];
    final puzzle = await ref
        .read(puzzleRepositoryProvider)
        .getFreePlayPuzzle(width: preset.width, height: preset.height);
    if (!mounted) return;
    setState(() => _generating = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(args: BoardArgs.freePlay(puzzle: puzzle)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.freePlaySizeSmall,
      l10n.freePlaySizeMedium,
      l10n.freePlaySizeLarge,
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
                for (var i = 0; i < _presets.length; i++)
                  ButtonSegment(
                    value: i,
                    label: Text(
                      '${labels[i]} '
                      '(${_presets[i].width}×${_presets[i].height})',
                    ),
                  ),
              ],
              selected: {_selectedIndex},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedIndex = selection.first),
            ),
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
