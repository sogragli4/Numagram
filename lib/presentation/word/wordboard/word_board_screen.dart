import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/domain/entities/word/word_clue.dart';
import 'package:nonogram_daily/presentation/word/wordboard/word_board_controller.dart';

/// The word puzzle's playable screen — a numbered clue list, per-letter
/// input boxes, instant correct/incorrect feedback, no heart cost. Faz 2
/// scaffolding: plays a fixed demo section (see `WordBoardController`),
/// not yet a real track/section sourced from a repository.
class WordBoardScreen extends ConsumerStatefulWidget {
  const WordBoardScreen({super.key});

  @override
  ConsumerState<WordBoardScreen> createState() => _WordBoardScreenState();
}

class _WordBoardScreenState extends ConsumerState<WordBoardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _hiddenController = TextEditingController();
  final FocusNode _hiddenFocusNode = FocusNode();
  late final AnimationController _flashController;

  String? _activeClueId;
  int? _activePosition;
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
    _hiddenController.dispose();
    _hiddenFocusNode.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _focusBox(String clueId, int position) {
    setState(() {
      _activeClueId = clueId;
      _activePosition = position;
    });
    _hiddenController.clear();
    _hiddenFocusNode.requestFocus();
  }

  void _handleHiddenChanged(String value) {
    if (value.isEmpty || _activeClueId == null || _activePosition == null) {
      return;
    }
    final letter = value.characters.last;
    final clueId = _activeClueId!;
    final position = _activePosition!;
    _hiddenController.clear();

    ref
        .read(wordBoardControllerProvider.notifier)
        .typeLetter(clueId: clueId, position: position, letter: letter);

    final session = ref.read(wordBoardControllerProvider).session;
    final letters = session.lettersByClueId[clueId]!;
    if (letters[position] == null) {
      // Wrong letter — stay on the same box so the player can retry it.
      return;
    }
    _advanceAfterCorrectLetter(clueId, letters);
  }

  void _advanceAfterCorrectLetter(String clueId, List<String?> letters) {
    final nextEmpty = letters.indexWhere((letter) => letter == null);
    if (nextEmpty != -1) {
      setState(() => _activePosition = nextEmpty);
      return;
    }

    final session = ref.read(wordBoardControllerProvider).session;
    final solved = session.solvedClueIds;
    WordClue? nextClue;
    for (final clue in session.section.clues) {
      if (!solved.contains(clue.id)) {
        nextClue = clue;
        break;
      }
    }
    if (nextClue == null) {
      setState(() {
        _activeClueId = null;
        _activePosition = null;
      });
      return;
    }
    _focusBox(nextClue.id, 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(wordBoardControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(wordBoardControllerProvider, (previous, next) {
      if (next.wrongFlashToken != _lastHandledFlashToken) {
        _lastHandledFlashToken = next.wrongFlashToken;
        _flashController
          ..stop()
          ..value = 1
          ..animateTo(0, curve: Curves.easeOut);
      }
      if ((previous == null || !previous.session.won) && next.session.won) {
        Future.microtask(() {
          if (!mounted) return;
          // ignore: use_build_context_synchronously, reason: guarded by mounted above
          _showWonDialog(context, l10n);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wordGameTitle)),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.session.section.clues.length,
            itemBuilder: (context, index) {
              final clue = state.session.section.clues[index];
              return _ClueRow(
                index: index + 1,
                clue: clue,
                letters: state.session.lettersByClueId[clue.id]!,
                activeClueId: _activeClueId,
                activePosition: _activePosition,
                wrongFlashClueId: state.wrongFlashClueId,
                wrongFlashPosition: state.wrongFlashPosition,
                flashController: _flashController,
                colorScheme: colorScheme,
                onTapBox: _focusBox,
              );
            },
          ),
          // Off-size but still mounted/focusable — captures raw keyboard
          // input one character at a time; visually invisible, the real
          // letters render from state via _ClueRow above.
          SizedBox.shrink(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _hiddenController,
                focusNode: _hiddenFocusNode,
                onChanged: _handleHiddenChanged,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
        ],
      ),
    );
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

class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.index,
    required this.clue,
    required this.letters,
    required this.activeClueId,
    required this.activePosition,
    required this.wrongFlashClueId,
    required this.wrongFlashPosition,
    required this.flashController,
    required this.colorScheme,
    required this.onTapBox,
  });

  final int index;
  final WordClue clue;
  final List<String?> letters;
  final String? activeClueId;
  final int? activePosition;
  final String? wrongFlashClueId;
  final int? wrongFlashPosition;
  final AnimationController flashController;
  final ColorScheme colorScheme;
  final void Function(String clueId, int position) onTapBox;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text('$index', style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clue.text),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: flashController,
                  builder: (context, _) => Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < letters.length; i++)
                        _LetterBox(
                          key: ValueKey('letterBox_${clue.id}_$i'),
                          letter: letters[i],
                          active:
                              activeClueId == clue.id && activePosition == i,
                          flashOpacity:
                              wrongFlashClueId == clue.id &&
                                  wrongFlashPosition == i
                              ? flashController.value
                              : 0,
                          colorScheme: colorScheme,
                          onTap: () => onTapBox(clue.id, i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterBox extends StatelessWidget {
  const _LetterBox({
    required super.key,
    required this.letter,
    required this.active,
    required this.flashOpacity,
    required this.colorScheme,
    required this.onTap,
  });

  final String? letter;
  final bool active;
  final double flashOpacity;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = flashOpacity > 0
        ? Color.lerp(colorScheme.outline, colorScheme.error, flashOpacity)!
        : active
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: active ? 2 : 1),
          borderRadius: BorderRadius.circular(4),
          color: flashOpacity > 0
              ? colorScheme.errorContainer.withValues(alpha: flashOpacity)
              : null,
        ),
        child: Text(
          letter ?? '',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
