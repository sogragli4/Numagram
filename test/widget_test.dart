import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/main.dart';
import 'package:nonogram_daily/presentation/settings/settings_controller.dart';
import 'package:nonogram_daily/services/ads/ad_service.dart';
import 'package:nonogram_daily/services/consent/consent_service.dart';

/// No real Google UMP / AppLovin MAX plugin is registered in a widget
/// test — `ConsentGate` already treats that failure as "stay disabled"
/// (see its own try/catch), but overriding with fakes here keeps this
/// test's intent explicit and its output quiet.
class _FakeConsentService implements ConsentService {
  @override
  Future<bool> resolveConsent() async => false;
}

class _FakeAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async => false;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Widget buildBanner() => const SizedBox.shrink();
}

void main() {
  testWidgets(
    'app boots into the game picker, and Nonogram opens the daily screen '
    'with a streak and play button',
    (WidgetTester tester) async {
      late Directory tempDir;
      late Isar isar;

      // All of it — opening Isar, pumping the widget, and waiting for the
      // streakForToday provider to resolve — happens inside one runAsync
      // block. Mixing tester.pump() with real async I/O across separate
      // runAsync calls deadlocks (the provider's Future gets bound to
      // testWidgets' fake-async zone partway through); staying in a single
      // real zone for the whole sequence avoids that entirely.
      await tester.runAsync(() async {
        tempDir = await Directory.systemTemp.createTemp('numagram_widget_test');
        isar = await Isar.open([
          PuzzleCompletionModelSchema,
          AppSettingsModelSchema,
        ], directory: tempDir.path);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              isarProvider.overrideWithValue(isar),
              initialAppSettingsProvider.overrideWithValue(
                // Explicitly past the tutorial: this test is about the game
                // picker and the daily screen, not the (separately tested)
                // tutorial flow — the real default is `false`, which would
                // otherwise boot into `TutorialScreen` instead.
                AppSettings.defaults.copyWith(hasSeenTutorial: true),
              ),
              consentServiceProvider.overrideWithValue(_FakeConsentService()),
              adServiceProvider.overrideWithValue(_FakeAdService()),
            ],
            child: const NonogramDailyApp(),
          ),
        );

        for (var i = 0; i < 20; i++) {
          if (find.byIcon(Icons.grid_on).evaluate().isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });

      addTearDown(() async {
        await tester.runAsync(() async {
          await isar.close(deleteFromDisk: true);
          if (tempDir.existsSync()) {
            await tempDir.delete(recursive: true);
          }
        });
      });

      // Landed on the game picker first — both game cards render.
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.grid_on));
        for (var i = 0; i < 20; i++) {
          if (find.byType(FilledButton).evaluate().isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });

      expect(find.byType(MaterialApp), findsOneWidget);
      // No completions recorded yet, so the "play today" button shows.
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );

  testWidgets('a first-ever launch boots into the tutorial, not the daily '
      'screen', (WidgetTester tester) async {
    late Directory tempDir;
    late Isar isar;

    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'numagram_widget_test_tutorial',
      );
      isar = await Isar.open([
        PuzzleCompletionModelSchema,
        AppSettingsModelSchema,
      ], directory: tempDir.path);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarProvider.overrideWithValue(isar),
            // The real default — `hasSeenTutorial: false` — is exactly
            // what this test wants to exercise.
            initialAppSettingsProvider.overrideWithValue(AppSettings.defaults),
            consentServiceProvider.overrideWithValue(_FakeConsentService()),
            adServiceProvider.overrideWithValue(_FakeAdService()),
          ],
          child: const NonogramDailyApp(),
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

    // The tutorial's intro step has no target cells, so its only action
    // is a "Continue"/`FilledButton` — the daily screen's "play today"
    // button would also be a `FilledButton`, so this alone wouldn't tell
    // them apart (see the sibling test above, which caught exactly that
    // gap). The "Skip tutorial" action is unique to the tutorial screen.
    expect(find.text('Skip tutorial'), findsOneWidget);
  });
}
