import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint("Failed to set local location, falling back to UTC: $e");
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    // 2. Initialize Flutter Local Notifications
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle when user taps notification (app opens)
      },
    );

    // 3. Request Permissions for Android 13+ (API 33+) & iOS
    try {
      await requestPermissions();
    } catch (e) {
      debugPrint("Failed to request notification permissions: $e");
    }
  }

  static Future<void> requestPermissions() async {
    // Android request
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationsPermission();

    // iOS request
    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    // Cancel any existing daily reminder to prevent duplicate schedules
    await _notificationsPlugin.cancel(0);

    final localNow = DateTime.now();
    DateTime localScheduled = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past for today, schedule it for tomorrow
    if (localScheduled.isBefore(localNow)) {
      localScheduled = localScheduled.add(const Duration(days: 1));
    }

    final scheduledDate = tz.TZDateTime.from(localScheduled, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_practice_reminder_channel',
          'Daily Practice Reminder',
          channelDescription:
              'Get daily reminders to practice speaking English.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        0,
        'Time to Practice English! 🎯',
        'Keep your streak alive! Open Argus and talk for 5 minutes.',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("Notification scheduled for: $scheduledDate");

      final pending = await _notificationsPlugin.pendingNotificationRequests();

      debugPrint("Pending Notifications: ${pending.length}");

      for (final n in pending) {
        debugPrint("ID: ${n.id}  Title: ${n.title}");
      }
    } catch (e) {
      debugPrint("Failed to schedule daily reminder: $e");
    }
  }
}
