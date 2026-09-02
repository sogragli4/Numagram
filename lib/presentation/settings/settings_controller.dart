import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nonogram_daily/core/injection.dart';
import 'package:nonogram_daily/domain/entities/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// The already-loaded settings at app start — overridden in `main()` with
/// the value read from `SettingsRepository` before `runApp`, same pattern
/// as `isarProvider`. Keeps every widget that reads settings synchronous.
final initialAppSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError(
    'initialAppSettingsProvider must be overridden with loaded settings',
  );
});

@riverpod
class AppSettingsController extends _$AppSettingsController {
  @override
  AppSettings build() => ref.watch(initialAppSettingsProvider);

  Future<void> setColorblindPalette({required bool enabled}) =>
      _update(state.copyWith(colorblindPalette: enabled));

  Future<void> setSoundEnabled({required bool enabled}) =>
      _update(state.copyWith(soundEnabled: enabled));

  /// [title]/[body] are only used if the reminder is currently enabled —
  /// changing the time re-schedules it, which needs them again.
  Future<void> setNotificationTime({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final wasEnabled = state.notificationsEnabled;
    await _update(
      state.copyWith(notificationHour: hour, notificationMinute: minute),
    );
    if (wasEnabled) {
      await ref
          .read(notificationServiceProvider)
          .scheduleDailyReminder(
            hour: hour,
            minute: minute,
            title: title,
            body: body,
          );
    }
  }

  /// Turns the daily reminder on/off. Turning it on for the first time is
  /// the caller's job to gate behind "has the player completed a puzzle
  /// yet" and an OS permission prompt — this method just persists the
  /// resulting preference and (de)schedules the notification.
  Future<void> setNotificationsEnabled({
    required bool enabled,
    required String title,
    required String body,
  }) async {
    await _update(state.copyWith(notificationsEnabled: enabled));
    if (enabled) {
      await ref
          .read(notificationServiceProvider)
          .scheduleDailyReminder(
            hour: state.notificationHour,
            minute: state.notificationMinute,
            title: title,
            body: body,
          );
    } else {
      await ref.read(notificationServiceProvider).cancelDailyReminder();
    }
  }

  /// Caller is responsible for only offering unlocked themes (see
  /// `AppColorTheme.isUnlockedAt`) — this just persists the choice.
  Future<void> selectColorTheme(String themeId) =>
      _update(state.copyWith(selectedThemeId: themeId));

  /// Records that the player has finished (or skipped) the tutorial —
  /// called whether they completed it or tapped "Skip", either way it
  /// shouldn't show again automatically.
  Future<void> markTutorialSeen() =>
      _update(state.copyWith(hasSeenTutorial: true));

  Future<void> markFirstPuzzleCompleted() =>
      _update(state.copyWith(hasCompletedFirstPuzzle: true));

  Future<void> incrementSessionCount() =>
      _update(state.copyWith(sessionCount: state.sessionCount + 1));

  Future<void> setLastKnownStreak(int streak) =>
      _update(state.copyWith(lastKnownStreak: streak));

  /// Records that an archive puzzle was opened on [todayKey] — resets the
  /// count to 1 if it was tracking a different (older) day.
  Future<void> recordArchiveUnlock(String todayKey) => _update(
    state.copyWith(
      archiveUnlocksDateKey: () => todayKey,
      archiveUnlocksCount: state.archiveUnlocksCountFor(todayKey) + 1,
    ),
  );

  Future<void> _update(AppSettings settings) async {
    state = settings;
    await ref.read(settingsRepositoryProvider).updateSettings(settings);
  }
}
