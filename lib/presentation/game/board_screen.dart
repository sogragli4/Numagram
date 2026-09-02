import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/core/theme.dart';
import 'package:nonogram_daily/domain/entities/cell_state.dart';
import 'package:nonogram_daily/domain/entities/game_session.dart';
import 'package:nonogram_daily/presentation/game/board_controller.dart';
import 'package:nonogram_daily/presentation/game/board_layout.dart';
import 'package:nonogram_daily/presentation/game/board_painter.dart';
import 'package:nonogram_daily/presentation/game/completion_sheet.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';

/// The playable board screen: renders the grid via [BoardPainter] and
/// wires input (tap, long-press-drag paint, pinch-zoom/pan, two-finger
/// mode toggle) to [BoardController]. Holds no game logic itself — every
/// callback just dispatches an intent to the controller.
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({required this.args, super.key});

  final BoardArgs args;

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _flashController;

  final Map<int, Offset> _pointerDownPositions = {};
  final Map<int, double> _pointerMaxMovement = {};
  DateTime? _twoFingerStartTime;
  int _lastHandledFlashToken = 0;

  static const _twoFingerTapWindow = Duration(milliseconds: 350);
  static const _twoFingerTapSlop = 16.0;

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
    _transformationController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPositions[event.pointer] = event.position;
    _pointerMaxMovement[event.pointer] = 0;
    if (_pointerDownPositions.length == 2) {
      _twoFingerStartTime = DateTime.now();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _pointerDownPositions[event.pointer];
    if (start == null) return;
    final moved = (event.position - start).distance;
    if (moved > (_pointerMaxMovement[event.pointer] ?? 0)) {
      _pointerMaxMovement[event.pointer] = moved;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final wasTwoFingerGesture =
        _pointerDownPositions.length == 2 && _twoFingerStartTime != null;
    if (wasTwoFingerGesture) {
      final elapsed = DateTime.now().difference(_twoFingerStartTime!);
      final bothStayedStill = _pointerMaxMovement.values.every(
        (m) => m < _twoFingerTapSlop,
      );
      if (elapsed < _twoFingerTapWindow && bothStayedStill) {
        ref.read(boardControllerProvider(widget.args).notifier).toggleMode();
      }
    }
    _pointerDownPositions.remove(event.pointer);
    _pointerMaxMovement.remove(event.pointer);
    if (_pointerDownPositions.length < 2) {
      _twoFingerStartTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(boardControllerProvider(widget.args));
    final controller = ref.read(boardControllerProvider(widget.args).notifier);
    final session = state.session;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(boardControllerProvider(widget.args), (previous, next) {
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
          showCompletionSheet(
            // ignore: use_build_context_synchronously, reason: guarded by mounted above
            context,
            elapsed: Duration(seconds: next.session.elapsedSeconds),
            heartsRemaining: next.session.heartsRemaining,
            solution: next.session.puzzle.solution,
            date: widget.args.date ?? DateTime.now(),
          );
        });
      }
      if ((previous == null || !previous.session.outOfHearts) &&
          next.session.outOfHearts) {
        Future.microtask(() {
          if (!mounted) return;
          // ignore: use_build_context_synchronously, reason: guarded by mounted above
          _showOutOfHeartsDialog(context, l10n);
        });
      }
    });

    final appSettings = ref.watch(appSettingsControllerProvider);
    final palette = appSettings.colorblindPalette
        ? BoardPalette.colorblindSafe
        : BoardPalette.standard;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < session.heartsRemaining
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: palette.wrongFlash,
                size: 20,
              ),
            const SizedBox(width: 12),
            Text(_formatElapsed(session.elapsedSeconds)),
          ],
        ),
        actions: [
          if (FeatureFlags.hintRewardedAdEnabled)
            IconButton(
              tooltip: l10n.watchAdForHint,
              icon: Badge(
                label: Text(
                  '${GameLimits.maxHintsPerPuzzle - session.hintsUsed}',
                ),
                isLabelVisible:
                    session.hintsUsed < GameLimits.maxHintsPerPuzzle,
                child: const Icon(Icons.lightbulb_outline),
              ),
              onPressed:
                  state.hintInFlight ||
                      session.isOver ||
                      session.hintsUsed >= GameLimits.maxHintsPerPuzzle
                  ? null
                  : controller.requestHint,
            ),
          IconButton(
            tooltip: l10n.colorblindPaletteLabel,
            icon: Icon(
              appSettings.colorblindPalette
                  ? Icons.visibility
                  : Icons.visibility_outlined,
            ),
            onPressed: () => ref
                .read(appSettingsControllerProvider.notifier)
                .setColorblindPalette(enabled: !appSettings.colorblindPalette),
          ),
          IconButton(
            tooltip: l10n.undoButtonLabel,
            icon: const Icon(Icons.undo),
            onPressed: state.canUndo ? controller.undo : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _fitBoardLayout(
                  session: session,
                  availableWidth: constraints.maxWidth,
                  availableHeight: constraints.maxHeight,
                );
                // The board always starts at scale 1 sized to fit the
                // viewport (see _fitBoardLayout) — maxScale lets a player
                // pinch in from there up to the true accessibility-minimum
                // 44pt touch target (BoardLayout.minTouchTargetSize) even
                // when the fitted cell size had to shrink below it, per
                // the "minimum 44pt effective touch target after zoom"
                // requirement.
                final double maxScale = math.max(
                  3,
                  BoardLayout.minTouchTargetSize / layout.cellSize,
                );
                return Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: Center(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1,
                      maxScale: maxScale,
                      boundaryMargin: const EdgeInsets.all(80),
                      child: GestureDetector(
                        onTapUp: (details) {
                          final cell = layout.cellAt(details.localPosition);
                          if (cell != null) {
                            controller.tapCell(cell.$1, cell.$2);
                          }
                        },
                        onLongPressStart: (details) {
                          final cell = layout.cellAt(details.localPosition);
                          if (cell != null) {
                            controller.startPaintStroke(cell.$1, cell.$2);
                          }
                        },
                        onLongPressMoveUpdate: (details) {
                          final cell = layout.cellAt(details.localPosition);
                          if (cell != null) {
                            controller.continuePaintStroke(cell.$1, cell.$2);
                          }
                        },
                        onLongPressEnd: (_) => controller.endPaintStroke(),
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _flashController,
                            builder: (context, _) => CustomPaint(
                              size: layout.totalSize,
                              painter: BoardPainter(
                                session: session,
                                layout: layout,
                                palette: palette,
                                gridLineColor: colorScheme.outlineVariant,
                                textColor: colorScheme.onSurface,
                                backgroundColor: colorScheme.surface,
                                wrongFlashRow: state.wrongFlashRow,
                                wrongFlashCol: state.wrongFlashCol,
                                wrongFlashOpacity: _flashController.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<CellState>(
                segments: [
                  ButtonSegment(
                    value: CellState.filled,
                    label: Text(l10n.boardModeFill),
                    icon: const Icon(Icons.grid_on),
                  ),
                  ButtonSegment(
                    value: CellState.marked,
                    label: Text(l10n.boardModeMark),
                    icon: const Icon(Icons.close),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (_) => controller.toggleMode(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOutOfHeartsDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final controller = ref.read(boardControllerProvider(widget.args).notifier);
    final canOfferExtraHeart =
        FeatureFlags.extraHeartRewardedAdEnabled &&
        !ref.read(boardControllerProvider(widget.args)).session.extraHeartUsed;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.outOfHeartsTitle),
        content: Text(l10n.outOfHeartsMessage),
        actions: [
          if (canOfferExtraHeart)
            OutlinedButton(
              onPressed: () async {
                await controller.requestExtraHeart();
                final stillOut = ref
                    .read(boardControllerProvider(widget.args))
                    .session
                    .outOfHearts;
                if (!stillOut && context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.watchAdForExtraHeart),
            ),
          FilledButton(
            onPressed: () {
              controller.restart();
              Navigator.of(context).pop();
            },
            child: Text(l10n.retryButtonLabel),
          ),
        ],
      ),
    );
  }

  String _formatElapsed(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// A cell size that fits [session]'s whole grid inside the available
  /// viewport at scale 1, capped at [BoardLayout.minTouchTargetSize] so a
  /// small grid (e.g. 5x5) never renders with oversized cells. Only once
  /// even the smallest reasonable cell size still can't fit (a large grid
  /// on a small screen) does the board fall back to the Phase 2 spec's
  /// pinch-to-zoom-and-pan behavior, rather than every grid size needing
  /// it regardless of how few cells it has.
  ///
  /// The clue gutter's width depends on the clue text alone, not on the
  /// final cell size (see `BoardLayout._gutterWidthFor`) — a first pass
  /// with the default (largest) cell size gets a safe, slightly-
  /// conservative gutter estimate to size the grid against, avoiding a
  /// circular cellSize-depends-on-gutter-depends-on-cellSize computation.
  BoardLayout _fitBoardLayout({
    required GameSession session,
    required double availableWidth,
    required double availableHeight,
  }) {
    final probe = BoardLayout(
      puzzleWidth: session.width,
      puzzleHeight: session.height,
      rowClues: session.puzzle.rowClues,
      columnClues: session.puzzle.columnClues,
    );
    final fitWidth = (availableWidth - probe.clueGutterWidth) / session.width;
    final fitHeight =
        (availableHeight - probe.clueGutterHeight) / session.height;
    final cellSize = math
        .min(fitWidth, fitHeight)
        .clamp(_minRenderedCellSize, BoardLayout.minTouchTargetSize);

    return BoardLayout(
      puzzleWidth: session.width,
      puzzleHeight: session.height,
      rowClues: session.puzzle.rowClues,
      columnClues: session.puzzle.columnClues,
      cellSize: cellSize,
    );
  }
}

/// Defensive floor only — keeps the fit computation from ever producing a
/// zero/negative cell size on a pathological (near-zero) viewport. Not an
/// accessibility target; [InteractiveViewer]'s pinch-zoom is what actually
/// gets a player from here up to a real touch-friendly size.
const _minRenderedCellSize = 8.0;
