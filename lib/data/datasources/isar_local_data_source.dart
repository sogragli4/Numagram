import 'package:isar_community/isar.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/data/models/puzzle_completion_model.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';

/// Thin wrapper around the Isar instance — every query/write the app
/// needs, in one place, so repositories don't touch Isar's API directly.
class IsarLocalDataSource {
  const IsarLocalDataSource(this._isar);

  final Isar _isar;

  /// No-ops if a completion for this [PuzzleCompletionModel.dateKey]
  /// already exists (idempotent: the first completion of a given day is
  /// the one that counts). Always saves free-play completions
  /// (`dateKey == null`).
  Future<void> saveCompletion(PuzzleCompletionModel model) {
    return _isar.writeTxn(() async {
      final dateKey = model.dateKey;
      if (dateKey != null) {
        final existing = await _isar.puzzleCompletionModels
            .filter()
            .dateKeyEqualTo(dateKey)
            .findFirst();
        if (existing != null) return;
      }
      await _isar.puzzleCompletionModels.put(model);
    });
  }

  Future<List<PuzzleCompletionModel>> allCompletions() =>
      _isar.puzzleCompletionModels.where().findAll();

  Future<AppSettingsModel> getSettings() async {
    final existing = await _isar.appSettingsModels.get(
      AppSettingsModel.fixedId,
    );
    return existing ?? AppSettingsModel.fromEntity(AppSettings.defaults);
  }

  Future<void> saveSettings(AppSettingsModel model) =>
      _isar.writeTxn(() => _isar.appSettingsModels.put(model));
}
