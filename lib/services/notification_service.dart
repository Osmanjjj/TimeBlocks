import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    
    // Request notification permission
    await Permission.notification.request();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  static Future<void> scheduleMultipleNotifications({
    required String taskId,
    required String title,
    String? body,
    required DateTime dueDate,
    required List<int> reminderMinutes,
  }) async {
    // Cancel existing notifications for this task
    await cancelTaskNotifications(taskId);

    for (int i = 0; i < reminderMinutes.length; i++) {
      final reminderTime = dueDate.subtract(Duration(minutes: reminderMinutes[i]));
      
      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: _generateNotificationId(taskId, i),
          title: _getReminderTitle(reminderMinutes[i]),
          body: title,
          scheduledDate: reminderTime,
        );
      }
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelTaskNotifications(String taskId) async {
    // Cancel up to 10 notifications per task (should be enough for all reminder types)
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(_generateNotificationId(taskId, i));
    }
  }

  static int _generateNotificationId(String taskId, int index) {
    // Generate a unique ID based on task ID and reminder index
    return (taskId.hashCode + index).abs() % 2147483647;
  }

  static String _getReminderTitle(int minutes) {
    if (minutes == 0) return 'タスクの期限です';
    if (minutes < 60) return '${minutes}分後にタスクの期限です';
    if (minutes < 1440) return '${(minutes / 60).round()}時間後にタスクの期限です';
    return '${(minutes / 1440).round()}日後にタスクの期限です';
  }
}
