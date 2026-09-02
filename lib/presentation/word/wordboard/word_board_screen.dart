import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/design_system/app_colors.dart';
import 'package:nonogram_daily/core/design_system/app_radius.dart';
import 'package:nonogram_daily/core/design_system/app_spacing.dart';
import 'package:nonogram_daily/core/design_system/app_typography.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/word/crossword_entry.dart';
import 'package:nonogram_daily/presentation/shared/app_button.dart';
import 'package:nonogram_daily/presentation/word/word_progress_controller.dart';
import 'package:nonogram_daily/presentation/word/wordboard/crossword_layout.dart';
import 'package:nonogram_daily/presentation/word/wordboard/crossword_painter.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_controller.dart';

const _keyboardRows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ'],
  ['Z', 'X', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç'],
];

/// The word puzzle's playable screen — a real intersecting crossword
/// grid, an active-clue navigator, a "Tüm İpuçları" sheet for the full
/// YATAY/DİKEY lists, and a custom on-screen Turkish keyboard. Faz 2
/// scaffolding: plays a fixed demo grid (see `WordBoardController`), not
/// yet a real track/section sourced from a repository.
class WordBoardScreen extends ConsumerStatefulWidget {
  const WordBoardScreen({super.key});

  @override
  ConsumerState<WordBoardScreen> createState() => _WordBoardScreenState();
}

class _WordBoardScreenState extends ConsumerState<WordBoardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  int _lastHandledFlashToken = 0;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _cycleEntry(int direction) {
    final state = ref.read(wordBoardControllerProvider);
    final entries = state.session.puzzle.entries;
    final currentIndex = entries.indexOf(state.activeEntry);
    final nextIndex = (currentIndex + direction) % entries.length;
    final wrapped = nextIndex < 0 ? nextIndex + entries.length : nextIndex;
    ref
        .read(wordBoardControllerProvider.notifier)
        .selectEntry(entries[wrapped]);
  }

  void _openAllClues(AppLocalizations l10n) {
    final state = ref.read(wordBoardControllerProvider);
    final across = state.session.puzzle.entries
        .where((e) => e.direction == CrosswordDirection.across)
        .toList();
    final down = state.session.puzzle.entries
        .where((e) => e.direction == CrosswordDirection.down)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ClueGroupHeader(label: l10n.wordAcrossLabel),
            for (final entry in across)
              _ClueListTile(
                entry: entry,
                onTap: () {
                  ref
                      .read(wordBoardControllerProvider.notifier)
                      .selectEntry(entry);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            _ClueGroupHeader(label: l10n.wordDownLabel),
            for (final entry in down)
              _ClueListTile(
                entry: entry,
                onTap: () {
                  ref
                      .read(wordBoardControllerProvider.notifier)
                      .selectEntry(entry);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(wordBoardControllerProvider);
    final appColors = context.appColors;
    final controller = ref.read(wordBoardControllerProvider.notifier);

    ref.listen(wordBoardControllerProvider, (previous, next) {
      if (next.wrongFlashToken != _lastHandledFlashToken) {
        _lastHandledFlashToken = next.wrongFlashToken;
        _flashController
          ..stop()
          ..value = 1
          ..animateTo(0, curve: Curves.easeOut);
      }
      if ((previous == null || !previous.session.won) && next.session.won) {
        final puzzle = next.session.puzzle;
        ref
            .read(wordProgressControllerProvider.notifier)
            .unlockNextSection(
              trackId: puzzle.trackId,
              sectionIndex: puzzle.sectionIndex,
            );
        Future.microtask(() {
          if (!mounted) return;
          // ignore: use_build_context_synchronously, reason: guarded by mounted above
          _showWonDialog(context, l10n);
        });
      }
    });

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(l10n.wordGameTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                l10n.wordMistakeCountLabel(state.mistakeCount),
                style: AppTypography.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = _fitCrosswordLayout(
                    width: state.session.puzzle.width,
                    height: state.session.puzzle.height,
                    availableWidth: constraints.maxWidth,
                    availableHeight: constraints.maxHeight,
                  );
                  return Center(
                    child: GestureDetector(
                      onTapUp: (details) {
                        final cell = layout.cellAt(details.localPosition);
                        if (cell == null) return;
                        final (row, col) = cell;
                        if (state.session.puzzle.isBlocked(row, col)) return;
                        final owner = _entryOwning(
                          state.session.puzzle.entries,
                          state.activeEntry,
                          row,
                          col,
                        );
                        controller.selectEntry(owner, atCell: cell);
                      },
                      child: AnimatedBuilder(
                        animation: _flashController,
                        builder: (context, _) => CustomPaint(
                          size: layout.totalSize,
                          painter: CrosswordPainter(
                            session: state.session,
                            layout: layout,
                            activeEntry: state.activeEntry,
                            activeCell: state.activeCell,
                            blockedColor: appColors.puzzleBlocked,
                            cellColor: appColors.puzzleCell,
                            gridLineColor: appColors.navy.withValues(
                              alpha: 0.15,
                            ),
                            textColor: appColors.navy,
                            activeEntryTint: appColors.puzzleWordSelected,
                            activeCellColor: appColors.puzzleCellSelected,
                            wrongFlashColor: appColors.puzzleWrong,
                            wrongFlashCell: state.wrongFlashCell,
                            wrongFlashOpacity: _flashController.value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _ActiveClueBar(
              entry: state.activeEntry,
              onPrevious: () => _cycleEntry(-1),
              onNext: () => _cycleEntry(1),
              onTapClueText: () => _openAllClues(l10n),
            ),
            _Toolbar(
              l10n: l10n,
              onClear: controller.clearActiveEntry,
              onShowAllClues: () => _openAllClues(l10n),
            ),
            _CrosswordKeyboard(onKey: controller.typeLetter),
          ],
        ),
      ),
    );
  }

  CrosswordEntry _entryOwning(
    List<CrosswordEntry> entries,
    CrosswordEntry current,
    int row,
    int col,
  ) {
    final owners = entries.where((entry) {
      for (var i = 0; i < entry.length; i++) {
        if (entry.cellAt(i) == (row, col)) return true;
      }
      return false;
    }).toList();
    if (owners.contains(current)) return current;
    return owners.isNotEmpty ? owners.first : current;
  }

  Future<void> _showWonDialog(BuildContext context, AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.puzzleCompletedTitle),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.continueButtonLabel),
          ),
        ],
      ),
    );
  }
}

/// A cell size that fits the whole grid inside the available viewport at
/// scale 1 — same fit-to-screen reasoning as `BoardScreen._fitBoardLayout`
/// (see the real-device board-overflow bug that method fixed), capped so
/// a small grid never renders oversized.
CrosswordLayout _fitCrosswordLayout({
  required int width,
  required int height,
  required double availableWidth,
  required double availableHeight,
}) {
  const maxCellSize = 56.0;
  const minCellSize = 24.0;
  final fitWidth = availableWidth / width;
  final fitHeight = availableHeight / height;
  final cellSize = fitWidth < fitHeight
      ? fitWidth.clamp(minCellSize, maxCellSize)
      : fitHeight.clamp(minCellSize, maxCellSize);
  return CrosswordLayout(width: width, height: height, cellSize: cellSize);
}

class _ActiveClueBar extends StatelessWidget {
  const _ActiveClueBar({
    required this.entry,
    required this.onPrevious,
    required this.onNext,
    required this.onTapClueText,
  });

  final CrosswordEntry entry;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTapClueText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final directionLabel = entry.direction == CrosswordDirection.across
        ? l10n.wordAcrossLabel
        : l10n.wordDownLabel;

    return Container(
      color: context.appColors.puzzleWordSelected,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapClueText,
              child: Text(
                '$directionLabel ${entry.clueNumber}: ${entry.clueText}',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium,
              ),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.l10n,
    required this.onClear,
    required this.onShowAllClues,
  });

  final AppLocalizations l10n;
  final VoidCallback onClear;
  final VoidCallback onShowAllClues;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: onShowAllClues,
            icon: Icons.list_alt,
            label: l10n.wordAllCluesLabel,
          ),
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: onClear,
            icon: Icons.backspace_outlined,
            label: l10n.wordClearEntryLabel,
          ),
        ],
      ),
    );
  }
}

class _ClueGroupHeader extends StatelessWidget {
  const _ClueGroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(label, style: AppTypography.headlineSmall),
    );
  }
}

class _ClueListTile extends StatelessWidget {
  const _ClueListTile({required this.entry, required this.onTap});

  final CrosswordEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: AppSpacing.lg,
        child: Text('${entry.clueNumber}.'),
      ),
      title: Text(entry.clueText),
      onTap: onTap,
    );
  }
}

/// A Turkish QWERTY on-screen keyboard, sized to the actual available
/// width rather than a fixed key size. A fixed 28dp/key × 12 keys (the
/// longest row) overflowed on a real phone, and — worth remembering for
/// next time — the *first* fix attempt still overflowed too: it clamped
/// the computed key width to a 24dp floor meant as a sane minimum, but
/// on a genuinely narrow phone (~360dp) the width that actually fits
/// (~22dp) is below that floor, so the floor itself pushed the row back
/// over budget. Widget tests didn't catch either version — the default
/// test surface is wider than a real phone — only the real-device check
/// did (see CLAUDE.MD's "Kelime Bulmacası" section). Same class of bug
/// `BoardScreen._fitBoardLayout` fixed for Nonogram's own grid, but that
/// one only needed an upper cap, never a lower floor tight enough to
/// bite back like this.
class _CrosswordKeyboard extends StatelessWidget {
  const _CrosswordKeyboard({required this.onKey});

  final void Function(String letter) onKey;

  static const _keyHorizontalMargin = 2.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final longestRow = _keyboardRows
                .map((row) => row.length)
                .reduce((a, b) => a > b ? a : b);
            final keyWidth =
                (constraints.maxWidth / longestRow) -
                (_keyHorizontalMargin * 2);
            // Only an upper cap (so keys don't balloon on a tablet) —
            // no lower floor, since the whole point of computing from
            // the real available width is to always fit it exactly.
            final clampedKeyWidth = keyWidth > 40.0 ? 40.0 : keyWidth;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final row in _keyboardRows)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs / 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final letter in row)
                          _KeyboardKey(
                            letter: letter,
                            width: clampedKeyWidth,
                            onKey: onKey,
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    required this.letter,
    required this.width,
    required this.onKey,
  });

  final String letter;
  final double width;
  final void Function(String letter) onKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _CrosswordKeyboard._keyHorizontalMargin,
      ),
      child: Material(
        color: context.appColors.puzzleWordSelected,
        borderRadius: AppRadius.smRadius,
        child: InkWell(
          borderRadius: AppRadius.smRadius,
          onTap: () => onKey(letter),
          child: SizedBox(
            width: width,
            height: AppSpacing.minTouchTarget,
            child: Center(child: Text(letter, style: AppTypography.labelLarge)),
          ),
        ),
      ),
    );
  }
}
