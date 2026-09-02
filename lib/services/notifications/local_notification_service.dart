import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nonogram_daily/services/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _dailyReminderNotificationId = 1;

/// [NotificationService] backed by `flutter_local_notifications`.
class LocalNotificationService implements NotificationService {
  LocalNotificationService() {
    tz_data.initializeTimeZones();
  }

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    // A null result means "this platform's plugin implementation wasn't
    // resolved" (e.g. running on desktop/web), which we treat as granted
    // since there's nothing to block scheduling on that platform.
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _dailyReminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily puzzle reminder',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact timing: a reminder doesn't need to-the-minute precision,
      // and this avoids needing Android 12+'s special "exact alarm"
      // permission for something this low-stakes.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _dailyReminderNotificationId);
  }
}
