import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Request notification permission on Android 13+
    try {
      await _requestPermissions();
    } catch (e) {
      debugPrint('Permission request error (non-fatal): $e');
    }

    // Initialize timezone with error handling
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Timezone init error (non-fatal): $e');
      // Fallback to UTC if timezone detection fails
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  Future<void> _requestPermissions() async {
    // Request Android notification permission
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
    
    // Request iOS permission
    final IOSFlutterLocalNotificationsPlugin? iosPlugin = 
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // The notification payload can be used to navigate to a specific screen
    // For now, this just ensures the app opens when tapped
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleHeartbeatReminder({DateTime? nextDue}) async {
    // Cancel existing one first
    await flutterLocalNotificationsPlugin.cancel(id: 1001);

    if (nextDue == null) return; // Do not schedule if we don't know when it's due
    if (nextDue.isBefore(DateTime.now())) return; // Do not schedule in the past

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'heartbeat_channel_v2',
      'Heartbeat Reminders',
      channelDescription: 'Recurring reminders to check-in for Proof of Life',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Check-in Required',
      enableVibration: true,
      vibrationPattern: Int64List.fromList(<int>[0, 500, 200, 500, 200, 500]),
      playSound: true,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT - continuous sound/vibration
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Schedule exact alarm
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1001,
      title: 'Vault Warning: Action Required 🚨',
      body: 'Your dead man\'s switch timer has hit exactly zero. Tap to check-in instantly.',
      scheduledDate: tz.TZDateTime.from(nextDue, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'heartbeat',
    );
  }

  Future<void> cancelHeartbeatReminder() async {
    await flutterLocalNotificationsPlugin.cancel(id: 1001);
  }

  /// Show an immediate test notification to verify notifications are working
  Future<void> showTestNotification() async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'heartbeat_channel_v2',
      'Heartbeat Reminders',
      channelDescription: 'Recurring reminders to check-in for Proof of Life',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(<int>[0, 500, 200, 500, 200, 500]),
      playSound: true,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id: 9999,
      title: 'Proof of Life Check-in ❤️',
      body: 'It\'s time to confirm you are safe. Tap to open and check-in now.',
      notificationDetails: platformDetails,
      payload: 'heartbeat_test',
    );
  }

  Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await flutterLocalNotificationsPlugin.show(id: id, title: title, body: body, notificationDetails: platformChannelSpecifics);
  }
}
