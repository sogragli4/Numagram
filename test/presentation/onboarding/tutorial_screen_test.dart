import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/core/l10n_gen/app_localizations.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/domain/usecases/tutorial_script.dart';
import 'package:nonogram_daily/presentation/game/board_layout.dart';
import 'package:nonogram_daily/presentation/game/board_painter.dart';
import 'package:nonogram_daily/presentation/onboarding/tutorial_screen.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';

void main() {
  testWidgets('walking through every guided step reaches the finished view and '
      'marks the tutorial seen', (WidgetTester tester) async {
    late Directory tempDir;
    late Isar isar;
    late ProviderContainer container;

    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'numagram_tutorial_screen_test',
      );
      isar = await Isar.open([
        PuzzleCompletionModelSchema,
        AppSettingsModelSchema,
      ], directory: tempDir.path);

      container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(isar),
          initialAppSettingsProvider.overrideWithValue(AppSettings.defaults),
        ],
      );
      addTearDown(container.dispose);
      // `AppSettingsController` is `@riverpod` (autoDispose). The real app
      // always has `_HomeRouter` watching it, keeping it alive; this test
      // pumps `TutorialScreen` directly (bypassing that router), so
      // without a listener of its own here, the provider disposes and
      // resets to `initialAppSettingsProvider`'s default the moment
      // nothing references it — silently losing `markTutorialSeen()`'s
      // effect before this test can observe it.
      container.listen(appSettingsControllerProvider, (_, _) {});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TutorialScreen(),
          ),
        ),
      );
      await tester.pump();
    });

    addTearDown(() async {
      await tester.runAsync(() async {
        await isar.close(deleteFromDisk: true);
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });
    });

    final puzzle = buildTutorialPuzzle();
    final layout = BoardLayout(
      puzzleWidth: puzzle.size.width,
      puzzleHeight: puzzle.size.height,
      rowClues: puzzle.rowClues,
      columnClues: puzzle.columnClues,
    );
    final boardFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is BoardPainter,
    );

    Future<void> tapCell(int row, int col) async {
      final boardTopLeft = tester.getTopLeft(boardFinder);
      final center = layout.cellRect(row, col).center;
      await tester.tapAt(boardTopLeft + Offset(center.dx, center.dy));
      await tester.pump();
    }

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Step 0 (intro): advance via "Continue".
    await tester.tap(find.text(l10n.continueButtonLabel));
    await tester.pump();

    // Step 1: fill the full row.
    for (var c = 0; c < 5; c++) {
      await tapCell(2, c);
    }

    // Step 2 (auto-mark explainer): advance via "Continue" again.
    await tester.tap(find.text(l10n.continueButtonLabel));
    await tester.pump();

    // Step 3: fill the rest of the full column — this also finishes the
    // whole puzzle, via the real engine's auto-mark behavior.
    for (final row in [0, 1, 3, 4]) {
      await tapCell(row, 2);
    }

    expect(find.text(l10n.tutorialFinishedTitle), findsOneWidget);

    // The tap and the wait for the real Isar write it triggers
    // (`markTutorialSeen`) must stay in the same `runAsync` call — see
    // `test/widget_test.dart`'s note on this exact gotcha.
    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.tutorialStartPlayingButtonLabel));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(
      container.read(appSettingsControllerProvider).hasSeenTutorial,
      isTrue,
    );
  });
}
