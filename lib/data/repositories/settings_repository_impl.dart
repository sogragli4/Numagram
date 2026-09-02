import 'package:nonogram_daily/data/datasources/isar_local_data_source.dart';
import 'package:nonogram_daily/data/models/app_settings_model.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._dataSource);

  final IsarLocalDataSource _dataSource;

  @override
  Future<AppSettings> getSettings() async =>
      (await _dataSource.getSettings()).toEntity();

  @override
  Future<void> updateSettings(AppSettings settings) =>
      _dataSource.saveSettings(AppSettingsModel.fromEntity(settings));
}
