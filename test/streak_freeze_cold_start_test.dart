import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/data/repositories/settings_repository_impl.dart';
import 'package:nonogram_daily/data/repositories/streak_repository_impl.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';
import 'package:nonogram_daily/domain/usecases/streak_freeze.dart';

/// Mirrors `main()`'s cold-start streak-freeze sequence exactly (monthly
/// grant check, then auto-freeze-yesterday check, then one persisted
/// write) against a real Isar instance — the pure decision functions are
/// covered by their own unit tests, but the actual field-by-field wiring
/// through `AppSettings.copyWith` → `AppSettingsModel.fromEntity` →
/// Isar → back is exactly the class of bug this project's own history
/// (see CLAUDE.MD) has caught before, and isn't exercised by any other
/// test — `test/widget_test.dart` pumps the widget tree directly with
/// `initialAppSettingsProvider` overridden, bypassing `main()` entirely.
Future<AppSettings> _runColdStartStreakFreezeLogic({
  required SettingsRepositoryImpl settingsRepository,
  required StreakRepositoryImpl streakRepository,
  required DateTime today,
}) async {
  final loadedSettings = await settingsRepository.getSettings();

  final todayMonthKey = formatMonthKey(today);
  var freezesAvailable = loadedSettings.streakFreezesAvailable;
  var freezeGrantMonthKey = loadedSettings.freezeGrantMonthKey;
  if (isNewMonthlyFreezeGrantDue(
    todayMonthKey: todayMonthKey,
    lastGrantMonthKey: freezeGrantMonthKey,
  )) {
    freezesAvailable = (freezesAvailable + StreakFreezeConfig.monthlyGrant)
        .clamp(0, StreakFreezeConfig.maxFreezesHeld);
    freezeGrantMonthKey = todayMonthKey;
  }

  var frozenDateKeys = loadedSettings.frozenDateKeys;
  final completedDates = await streakRepository.getCompletedDates();
  final frozenDates = frozenDateKeys.map(parseDateKey).toSet();
  if (shouldAutoFreezeYesterday(
    completedDates: completedDates,
    frozenDates: frozenDates,
    today: today,
    freezesAvailable: freezesAvailable,
  )) {
    final yesterdayKey = formatDateKey(today.subtract(const Duration(days: 1)));
    frozenDateKeys = [...frozenDateKeys, yesterdayKey];
    freezesAvailable -= 1;
  }

  final updated = loadedSettings.copyWith(
    streakFreezesAvailable: freezesAvailable,
    frozenDateKeys: frozenDateKeys,
    freezeGrantMonthKey: () => freezeGrantMonthKey,
  );
  await settingsRepository.updateSettings(updated);
  return updated;
}

void main() {
  late Directory tempDir;
  late Isar isar;
  late SettingsRepositoryImpl settingsRepository;
  late StreakRepositoryImpl streakRepository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'numagram_streak_freeze_cold_start',
    );
    isar = await Isar.open([
      PuzzleCompletionModelSchema,
      AppSettingsModelSchema,
    ], directory: tempDir.path);
    final dataSource = IsarLocalDataSource(isar);
    settingsRepository = SettingsRepositoryImpl(dataSource);
    streakRepository = StreakRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'a real missed-yesterday gap gets frozen and persisted through Isar',
    () async {
      // Completed the day before yesterday, nothing since — a real gap
      // a freeze should bridge.
      await streakRepository.recordCompletion(
        PuzzleCompletion(
          date: DateTime(2026, 9, 8),
          size: const GridSize(10, 10),
          difficulty: Difficulty.medium,
          elapsedSeconds: 120,
          mistakeCount: 0,
          completedAt: DateTime(2026, 9, 8, 12),
        ),
      );

      final result = await _runColdStartStreakFreezeLogic(
        settingsRepository: settingsRepository,
        streakRepository: streakRepository,
        today: DateTime(2026, 9, 10),
      );

      // This is also a first-ever run, so the monthly grant fires too:
      // 1 (default) + 1 (grant, capped at 2) = 2, then -1 spent on the
      // freeze = 1.
      expect(result.frozenDateKeys, contains('2026-09-09'));
      expect(result.streakFreezesAvailable, 1);

      // Re-read from Isar directly — confirms the write actually landed,
      // not just the in-memory `updated` value this function returned.
      final rereadSettings = await settingsRepository.getSettings();
      expect(rereadSettings.frozenDateKeys, contains('2026-09-09'));
      expect(rereadSettings.streakFreezesAvailable, 1);
    },
  );

  test('a genuine first-ever monthly grant is persisted', () async {
    final result = await _runColdStartStreakFreezeLogic(
      settingsRepository: settingsRepository,
      streakRepository: streakRepository,
      today: DateTime(2026, 9, 10),
    );

    expect(result.freezeGrantMonthKey, '2026-09');
    // 1 (default) + 1 (grant) = 2, nothing spent — no gap to freeze.
    expect(result.streakFreezesAvailable, 2);
  });

  test('no gap to freeze leaves frozenDateKeys empty', () async {
    await streakRepository.recordCompletion(
      PuzzleCompletion(
        date: DateTime(2026, 9, 9),
        size: const GridSize(10, 10),
        difficulty: Difficulty.medium,
        elapsedSeconds: 120,
        mistakeCount: 0,
        completedAt: DateTime(2026, 9, 9, 12),
      ),
    );

    final result = await _runColdStartStreakFreezeLogic(
      settingsRepository: settingsRepository,
      streakRepository: streakRepository,
      today: DateTime(2026, 9, 10),
    );

    expect(result.frozenDateKeys, isEmpty);
  });

  test('the monthly grant never pushes freezes past the cap', () async {
    // Seed settings as if the player already holds the max, with this
    // month's grant already claimed — a second run in the same month
    // (e.g. reopening the app twice) must not grant again.
    await settingsRepository.updateSettings(
      AppSettings.defaults.copyWith(
        streakFreezesAvailable: StreakFreezeConfig.maxFreezesHeld,
        freezeGrantMonthKey: () => '2026-09',
      ),
    );

    final result = await _runColdStartStreakFreezeLogic(
      settingsRepository: settingsRepository,
      streakRepository: streakRepository,
      today: DateTime(2026, 9, 10),
    );

    expect(result.streakFreezesAvailable, StreakFreezeConfig.maxFreezesHeld);
  });
}
