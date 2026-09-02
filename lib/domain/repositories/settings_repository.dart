import 'package:nonogram_daily/domain/entities/app_settings.dart';

/// Persists [AppSettings]. Added in Phase 3 alongside the rest of the
/// persistence layer — not in the original Phase 0 skeleton, but the
/// settings screen (notification time, colourblind palette) needs
/// somewhere durable to live.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
}
