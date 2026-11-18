import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../health_logic.dart';
import '../models.dart';

/// Daily local medicine reminders, scheduled in the device's timezone.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'vitalkin_medicines',
          'Medicine reminders',
          channelDescription: 'Daily reminders to take medicines',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  /// Schedules one daily notification per time slot for a medicine.
  /// Notification ids are derived from the medicine id so rescheduling
  /// and cancelling stay consistent.
  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    if (medicine.id == null) return;
    await init();
    for (var i = 0; i < medicine.times.length; i++) {
      final time = parseTimeOfDay(medicine.times[i]);
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: medicine.id! * 10 + i,
        title: 'Time for ${medicine.name}',
        body: '${medicine.dose} — tap to open VitalKin',
        scheduledDate: scheduled,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelMedicineReminders(Medicine medicine) async {
    if (medicine.id == null) return;
    for (var i = 0; i < medicine.times.length; i++) {
      await _plugin.cancel(id: medicine.id! * 10 + i);
    }
  }
}
