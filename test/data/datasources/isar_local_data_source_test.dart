import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/domain/entities/difficulty.dart';
import 'package:nonogram_daily/domain/entities/grid_size.dart';
import 'package:nonogram_daily/domain/entities/puzzle_completion.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late IsarLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('numagram_isar_test');
    isar = await Isar.open([
      PuzzleCompletionModelSchema,
      AppSettingsModelSchema,
    ], directory: tempDir.path);
    dataSource = IsarLocalDataSource(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('IsarLocalDataSource completions', () {
    test('saves and reads back a completion', () async {
      final completion = PuzzleCompletion(
        date: DateTime(2026, 9),
        size: const GridSize(10, 10),
        difficulty: Difficulty.medium,
        elapsedSeconds: 120,
        mistakeCount: 0,
        completedAt: DateTime(2026, 9, 1, 12),
      );
      await dataSource.saveCompletion(
        PuzzleCompletionModel.fromEntity(completion),
      );

      final all = await dataSource.allCompletions();
      expect(all, hasLength(1));
      expect(all.single.dateKey, '2026-09-01');
      expect(all.single.toEntity().elapsedSeconds, 120);
    });

    test('does not duplicate a completion for the same date', () async {
      final completion = PuzzleCompletion(
        date: DateTime(2026, 9),
        size: const GridSize(10, 10),
        difficulty: Difficulty.medium,
        elapsedSeconds: 60,
        mistakeCount: 1,
        completedAt: DateTime(2026, 9),
      );
      await dataSource.saveCompletion(
        PuzzleCompletionModel.fromEntity(completion),
      );
      // Replaying the same date (e.g. re-solving an already-solved
      // archive puzzle) must not create a second row.
      await dataSource.saveCompletion(
        PuzzleCompletionModel.fromEntity(completion),
      );

      final all = await dataSource.allCompletions();
      expect(all, hasLength(1));
    });

    test('allows multiple free-play completions (null dateKey)', () async {
      for (var i = 0; i < 3; i++) {
        await dataSource.saveCompletion(
          PuzzleCompletionModel.fromEntity(
            PuzzleCompletion(
              date: null,
              size: const GridSize(5, 5),
              difficulty: Difficulty.easy,
              elapsedSeconds: 30,
              mistakeCount: 0,
              completedAt: DateTime(2026, 9),
            ),
          ),
        );
      }
      final all = await dataSource.allCompletions();
      expect(all.where((m) => m.dateKey == null), hasLength(3));
    });
  });

  group('IsarLocalDataSource settings', () {
    test('returns defaults when nothing has been saved yet', () async {
      final settings = await dataSource.getSettings();
      expect(
        settings.toEntity().notificationHour,
        AppSettings.defaults.notificationHour,
      );
    });

    test('saves and reads back updated settings', () async {
      final updated = AppSettings.defaults.copyWith(
        notificationHour: 20,
        notificationsEnabled: true,
      );
      await dataSource.saveSettings(AppSettingsModel.fromEntity(updated));

      final settings = (await dataSource.getSettings()).toEntity();
      expect(settings.notificationHour, 20);
      expect(settings.notificationsEnabled, isTrue);
    });
  });
}
