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
  testWidgets('app boots into the daily screen with a streak and play '
      'button', (WidgetTester tester) async {
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
            initialAppSettingsProvider.overrideWithValue(AppSettings.defaults),
            consentServiceProvider.overrideWithValue(_FakeConsentService()),
            adServiceProvider.overrideWithValue(_FakeAdService()),
          ],
          child: const NonogramDailyApp(),
        ),
      );

      for (var i = 0; i < 20; i++) {
        if (find.byType(FilledButton).evaluate().isNotEmpty) break;
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

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    // No completions recorded yet, so the "play today" button shows.
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
