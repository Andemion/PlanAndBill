import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:planandbill/models/appointment.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const _keyPushNotifications = 'push_notifications_enabled';
  static const _keyDailyReminder = 'daily_reminder_enabled';
  static const _keyDailyReminderTime = 'daily_reminder_time';
  static const MethodChannel _channel = MethodChannel('exact_alarm_permission');
  static late tz.Location _localLocation;

  /// INITIALIZE
  static Future<void> initialize() async {
    // Load timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    _localLocation = tz.getLocation(timeZoneName);
    tz.setLocalLocation(_localLocation);

    // Init notifications
    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // ✅ Create notification channel for Android 8+
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'appointments_channel',
        'Appointments',
        description: 'Reminders for appointments',
        importance: Importance.max,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // ✅ Android 13+ permission
      final status = await Permission.notification.request();
      print('🔐 Notification permission status: $status');
    }
  }

  /// SCHEDULE APPOINTMENT
  static Future<void> scheduleAppointmentNotification(Appointment appointment) async {
    final notificationsEnabled = await getPushNotifications();
    if (!notificationsEnabled) return;

    // Heure exacte = 1h avant le RDV
    final scheduledDateTime = appointment.date.subtract(const Duration(hours: 1));
    final scheduledTz = tz.TZDateTime.from(scheduledDateTime, _localLocation);

    await _notificationsPlugin.zonedSchedule(
      appointment.hashCode,
      'Upcoming Appointment',
      'You have an appointment at ${appointment.time}',
      scheduledTz,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments_channel',
          'Appointments',
          channelDescription: 'Reminders for appointments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null, // 👈 Important pour une exécution unique
    );

    print('📅 RDV prévu à : ${appointment.date}');
    print('⏰ Notification programmée à : $scheduledTz (${_localLocation.name})');

    // 🔍 Vérification
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    print('🕵️ Notifications en attente : ${pending.length}');
    for (var n in pending) {
      print('🔔 ${n.id} | ${n.title} | ${n.body}');
    }
  }

  /// Shared Preferences – Push
  static Future<void> setPushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotifications, value);
  }

  static Future<bool> getPushNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPushNotifications) ?? false;
  }

  /// Shared Preferences – Daily
  static Future<void> setDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, value);
  }

  static Future<bool> getDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminder) ?? false;
  }

  /// Shared Preferences – Daily Time
  static Future<void> setDailyReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyReminderTime, '${time.hour}:${time.minute}');
  }

  static Future<TimeOfDay> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_keyDailyReminderTime);
    if (timeString != null) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return const TimeOfDay(hour: 20, minute: 0); // valeur par défaut
  }

  /// Exact Alarm – Android 12+
  static Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 31) {
      final isGranted = await _channel.invokeMethod<bool>('isExactAlarmAllowed');
      print('⏱️ Exact alarm allowed: $isGranted');
      if (isGranted == true) return;

      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    }
  }

  /// Cancel all
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('❌ Toutes les notifications ont été annulées');
  }

  static Future<void> scheduleTestNotification(tz.TZDateTime when) async {
    await _notificationsPlugin.zonedSchedule(
      99999,
      '🔔 Test Notification',
      'Ceci est une notification de test',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments_channel',
          'Appointments',
          channelDescription: 'Reminders for appointments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('✅ Notification test planifiée pour $when');
  }
  static tz.Location getLocalTimeZone() {
    return _localLocation;
  }
}
