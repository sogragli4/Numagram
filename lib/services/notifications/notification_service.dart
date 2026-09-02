/// Local daily-reminder notifications, behind an interface so it can be
/// faked in tests and left inert in debug builds that don't want to poke
/// the OS notification system.
///
/// Titles/bodies are passed in by the caller rather than hardcoded here,
/// so this service never needs its own copy of localized strings — it has
/// no `BuildContext` to read them from.
abstract class NotificationService {
  /// Prompts the OS permission dialog. Callers must only invoke this
  /// after the player has completed their first puzzle — never on
  /// launch (Phase 3 spec).
  Future<bool> requestPermission();

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  Future<void> cancelDailyReminder();
}
