import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:planandbill/models/appointment.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    tz.initializeTimeZones();
    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> scheduleAppointmentNotification(Appointment appointment) async {
    final scheduledDateTime = appointment.date.subtract(const Duration(hours: 1));
    final scheduledTz = tz.TZDateTime.from(scheduledDateTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      appointment.hashCode, // unique ID
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
    );
  }
}
