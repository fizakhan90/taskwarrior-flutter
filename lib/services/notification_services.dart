// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings _androidInitializationSettings =
      const AndroidInitializationSettings('taskwarrior');
  DarwinInitializationSettings iosSettings = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestCriticalPermission: true,
      requestSoundPermission: true);

  void initiliazeNotification() async {
    InitializationSettings initializationSettings = InitializationSettings(
        android: _androidInitializationSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Function to create a unique notification ID
  int calculateNotificationId(
      DateTime scheduledTime, String taskname, int? taskid) {
    String combinedString = '${scheduledTime.toIso8601String()}$taskname';

    // Calculate SHA-256 hash
    var sha2561 = sha256.convert(utf8.encode(combinedString));

    // Convert the first 8 characters of the hash to an integer
    int notificationId =
        int.parse(sha2561.toString().substring(0, 8), radix: 16) % 2147483647;
    if (taskid != null) {
      notificationId = (notificationId + taskid) % 2147483647;
    }

    return notificationId;
  }

  void sendNotification(DateTime dtb, String taskname, int? taskid) async {
    DateTime dateTime = DateTime.now();
    tz.initializeTimeZones();
    if (kDebugMode) {
      print("date and time are:-$dateTime");
      print("date and time are:-$dtb");
    }
    final tz.TZDateTime scheduledAt =
        tz.TZDateTime.from(dtb.add(const Duration(minutes: 0)), tz.local);

    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails('channelId', 'TaskReminder',
            icon: "taskwarrior",
            importance: Importance.max,
            priority: Priority.max);

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    // Generate a unique notification ID based on the scheduled time and task name
    int notificationId = calculateNotificationId(dtb, taskname, taskid);

    await _flutterLocalNotificationsPlugin
        .zonedSchedule(
            notificationId,
            'Task Warrior Reminder',
            'Hey! Your task of $taskname is still pending',
            scheduledAt,
            notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            // ignore: deprecated_member_use
            androidAllowWhileIdle: true)
        .then((value) {
      if (kDebugMode) {
        print('Notification scheduled successfully');
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('Error scheduling notification: $error');
      }
    });

    if (kDebugMode) {
      print(scheduledAt.day * 100 + scheduledAt.hour * 10 + scheduledAt.minute);
    }
  }

  // Delete previously scheduled notification with a specific ID
  void cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }
}
