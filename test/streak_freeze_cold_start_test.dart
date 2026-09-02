import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/data/repositories/settings_repository_impl.dart';
import 'package:nonogram_daily/data/repositories/streak_repository_impl.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';
import 'package:nonogram_daily/domain/usecases/apply_streak_freeze.dart';

/// Exercises the real `ApplyStreakFreeze` usecase — the same class
/// `main()` calls at cold start and `_NonogramDailyAppState` calls again
/// on every app resume — against a real Isar instance. The pure decision
/// functions it delegates to are covered by their own unit tests, but the
/// actual field-by-field wiring through `AppSettings.copyWith` →
/// `AppSettingsModel.fromEntity` → Isar → back is exactly the class of
/// bug this project's own history (see CLAUDE.MD) has caught before, and
/// isn't exercised by any other test — `test/widget_test.dart` pumps the
/// widget tree directly with `initialAppSettingsProvider` overridden,
/// bypassing `main()` (and this usecase) entirely.
void main() {
  late Directory tempDir;
  late Isar isar;
  late SettingsRepositoryImpl settingsRepository;
  late ApplyStreakFreeze applyStreakFreeze;

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
    applyStreakFreeze = ApplyStreakFreeze(
      settingsRepository,
      StreakRepositoryImpl(dataSource),
    );
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
      final dataSource = IsarLocalDataSource(isar);
      // Completed the day before yesterday, nothing since — a real gap
      // a freeze should bridge.
      await StreakRepositoryImpl(dataSource).recordCompletion(
        PuzzleCompletion(
          date: DateTime(2026, 9, 8),
          size: const GridSize(10, 10),
          difficulty: Difficulty.medium,
          elapsedSeconds: 120,
          mistakeCount: 0,
          completedAt: DateTime(2026, 9, 8, 12),
        ),
      );

      final loadedSettings = await settingsRepository.getSettings();
      final result = await applyStreakFreeze.call(
        currentSettings: loadedSettings,
        today: DateTime(2026, 9, 10),
      );

      // This is also a first-ever run, so the monthly grant fires too:
      // 1 (default) + 1 (grant, capped at 2) = 2, then -1 spent on the
      // freeze = 1.
      expect(result.frozenDateKeys, contains('2026-09-09'));
      expect(result.streakFreezesAvailable, 1);

      // Re-read from Isar directly — confirms the write actually landed,
      // not just the in-memory `result` this call returned.
      final rereadSettings = await settingsRepository.getSettings();
      expect(rereadSettings.frozenDateKeys, contains('2026-09-09'));
      expect(rereadSettings.streakFreezesAvailable, 1);
    },
  );

  test('a genuine first-ever monthly grant is persisted', () async {
    final loadedSettings = await settingsRepository.getSettings();
    final result = await applyStreakFreeze.call(
      currentSettings: loadedSettings,
      today: DateTime(2026, 9, 10),
    );

    expect(result.freezeGrantMonthKey, '2026-09');
    // 1 (default) + 1 (grant) = 2, nothing spent — no gap to freeze.
    expect(result.streakFreezesAvailable, 2);
  });

  test('no gap to freeze leaves frozenDateKeys empty', () async {
    final dataSource = IsarLocalDataSource(isar);
    await StreakRepositoryImpl(dataSource).recordCompletion(
      PuzzleCompletion(
        date: DateTime(2026, 9, 9),
        size: const GridSize(10, 10),
        difficulty: Difficulty.medium,
        elapsedSeconds: 120,
        mistakeCount: 0,
        completedAt: DateTime(2026, 9, 9, 12),
      ),
    );

    final loadedSettings = await settingsRepository.getSettings();
    final result = await applyStreakFreeze.call(
      currentSettings: loadedSettings,
      today: DateTime(2026, 9, 10),
    );

    expect(result.frozenDateKeys, isEmpty);
  });

  test('the monthly grant never pushes freezes past the cap', () async {
    // Seed settings as if the player already holds the max, with this
    // month's grant already claimed — a second run in the same month
    // (e.g. reopening the app twice) must not grant again.
    final seeded = AppSettings.defaults.copyWith(
      streakFreezesAvailable: StreakFreezeConfig.maxFreezesHeld,
      freezeGrantMonthKey: () => '2026-09',
    );
    await settingsRepository.updateSettings(seeded);

    final result = await applyStreakFreeze.call(
      currentSettings: seeded,
      today: DateTime(2026, 9, 10),
    );

    expect(result.streakFreezesAvailable, StreakFreezeConfig.maxFreezesHeld);
  });

  test('calling it twice in a row (cold start, then an app-resume re-check) '
      'is idempotent', () async {
    // Mirrors main.dart's cold start immediately followed by
    // _NonogramDailyAppState re-checking on the very next app resume —
    // the second call must not double-grant or double-freeze.
    final dataSource = IsarLocalDataSource(isar);
    await StreakRepositoryImpl(dataSource).recordCompletion(
      PuzzleCompletion(
        date: DateTime(2026, 9, 8),
        size: const GridSize(10, 10),
        difficulty: Difficulty.medium,
        elapsedSeconds: 120,
        mistakeCount: 0,
        completedAt: DateTime(2026, 9, 8, 12),
      ),
    );

    final loadedSettings = await settingsRepository.getSettings();
    final first = await applyStreakFreeze.call(
      currentSettings: loadedSettings,
      today: DateTime(2026, 9, 10),
    );
    final second = await applyStreakFreeze.call(
      currentSettings: first,
      today: DateTime(2026, 9, 10),
    );

    expect(second.frozenDateKeys, first.frozenDateKeys);
    expect(second.streakFreezesAvailable, first.streakFreezesAvailable);
    expect(second.freezeGrantMonthKey, first.freezeGrantMonthKey);
  });

  test('a day missed entirely while the app was only resumed (no relaunch) '
      'still gets frozen on the next resume check', () async {
    // Simulates main.dart's cold start on day N (nothing to freeze
    // yet), then the app staying backgrounded-but-alive across
    // midnight, then a resume re-check on day N+2 discovering
    // yesterday (N+1) needs freezing — exactly the gap this usecase
    // exists to close, now that it isn't only ever called once.
    final dataSource = IsarLocalDataSource(isar);
    await StreakRepositoryImpl(dataSource).recordCompletion(
      PuzzleCompletion(
        date: DateTime(2026, 9, 8),
        size: const GridSize(10, 10),
        difficulty: Difficulty.medium,
        elapsedSeconds: 120,
        mistakeCount: 0,
        completedAt: DateTime(2026, 9, 8, 12),
      ),
    );

    final loadedSettings = await settingsRepository.getSettings();
    final coldStart = await applyStreakFreeze.call(
      currentSettings: loadedSettings,
      today: DateTime(2026, 9, 9),
    );
    expect(coldStart.frozenDateKeys, isEmpty);

    final resumeCheck = await applyStreakFreeze.call(
      currentSettings: coldStart,
      today: DateTime(2026, 9, 10),
    );

    expect(resumeCheck.frozenDateKeys, contains('2026-09-09'));
  });
}
