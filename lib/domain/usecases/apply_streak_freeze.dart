import 'package:nonogram_daily/core/constants.dart';
import 'package:nonogram_daily/core/date_key.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:nonogram_daily/domain/repositories/settings_repository.dart';
import 'package:nonogram_daily/domain/repositories/streak_repository.dart';
import 'package:nonogram_daily/domain/usecases/streak_freeze.dart';

/// Checks for a due monthly streak-freeze grant and a missed-yesterday
/// gap, persists the result if either applies, and returns the settings
/// as they now stand.
///
/// Idempotent (safe to call repeatedly): the date-key comparisons inside
/// `isNewMonthlyFreezeGrantDue`/`shouldAutoFreezeYesterday` already make
/// a repeat call with unchanged inputs a no-op. That's what makes this
/// safe to call from more than one place — at cold start (`main()`) *and*
/// whenever the app resumes from background — so a day missed while the
/// app was merely backgrounded (not relaunched) across a midnight
/// boundary still gets a chance to be frozen, instead of only ever being
/// checked once per process launch.
class ApplyStreakFreeze {
  const ApplyStreakFreeze(this._settingsRepository, this._streakRepository);

  final SettingsRepository _settingsRepository;
  final StreakRepository _streakRepository;

  Future<AppSettings> call({
    required AppSettings currentSettings,
    required DateTime today,
  }) async {
    final todayMonthKey = formatMonthKey(today);
    var freezesAvailable = currentSettings.streakFreezesAvailable;
    var freezeGrantMonthKey = currentSettings.freezeGrantMonthKey;
    if (isNewMonthlyFreezeGrantDue(
      todayMonthKey: todayMonthKey,
      lastGrantMonthKey: freezeGrantMonthKey,
    )) {
      freezesAvailable = (freezesAvailable + StreakFreezeConfig.monthlyGrant)
          .clamp(0, StreakFreezeConfig.maxFreezesHeld);
      freezeGrantMonthKey = todayMonthKey;
    }

    var frozenDateKeys = currentSettings.frozenDateKeys;
    final completedDates = await _streakRepository.getCompletedDates();
    final frozenDates = frozenDateKeys.map(parseDateKey).toSet();
    if (shouldAutoFreezeYesterday(
      completedDates: completedDates,
      frozenDates: frozenDates,
      today: today,
      freezesAvailable: freezesAvailable,
    )) {
      final yesterdayKey = formatDateKey(
        today.subtract(const Duration(days: 1)),
      );
      frozenDateKeys = [...frozenDateKeys, yesterdayKey];
      freezesAvailable -= 1;
    }

    final updated = currentSettings.copyWith(
      streakFreezesAvailable: freezesAvailable,
      frozenDateKeys: frozenDateKeys,
      freezeGrantMonthKey: () => freezeGrantMonthKey,
    );

    final changed =
        updated.streakFreezesAvailable !=
            currentSettings.streakFreezesAvailable ||
        updated.frozenDateKeys.length !=
            currentSettings.frozenDateKeys.length ||
        updated.freezeGrantMonthKey != currentSettings.freezeGrantMonthKey;
    if (changed) {
      await _settingsRepository.updateSettings(updated);
    }
    return updated;
  }
}
