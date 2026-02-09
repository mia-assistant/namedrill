import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../constants/app_constants.dart';

/// Service to manage local notifications for daily practice reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialization ──────────────────────────────────────────────────

  /// Must be called once at app startup (e.g. in main()).
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();
    final localTz = _resolveLocalTimezone();
    tz.setLocalLocation(localTz);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            description: AppConstants.notificationChannelDesc,
            importance: Importance.defaultImportance,
          ),
        );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  // ─── Permission handling ─────────────────────────────────────────────

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return false;
  }

  /// Check whether notification permission is currently granted.
  Future<bool> hasPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    }

    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }

    return false;
  }

  // ─── Schedule / Cancel ───────────────────────────────────────────────

  /// Schedule a daily repeating reminder at [hour]:[minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Cancel any existing reminder first
    await cancelAllReminders();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _kDailyReminderId,
      'Time to practice! 🧠',
      'A quick session keeps names fresh. Let\'s go!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
        'Daily reminder scheduled for $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    await _plugin.cancel(_kDailyReminderId);
    debugPrint('All reminders cancelled');
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  static const int _kDailyReminderId = 0;

  void _onNotificationTapped(NotificationResponse response) {
    // The app opens to its default route; nothing else needed.
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Best-effort local timezone resolution.
  tz.Location _resolveLocalTimezone() {
    try {
      // Try the platform timezone name first (e.g. "America/New_York")
      final name = DateTime.now().timeZoneName;
      return tz.getLocation(name);
    } catch (_) {
      // Abbreviations like "EST" aren't in the tz database.
      // Fall back to computing from the UTC offset.
      final offset = DateTime.now().timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          return loc;
        }
      }
      return tz.UTC;
    }
  }
}
