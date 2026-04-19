import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys (must be readable by background isolate)
// ─────────────────────────────────────────────────────────────────────────────
const String _kNextDueKey = 'heartbeat_next_due_iso';
const String _kAlarmActiveKey = 'heartbeat_alarm_active';

/// Call once from main() before runApp().
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create the low-importance foreground channel (just "monitoring" status bar)
  final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
  await flnp
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'heartbeat_bg_channel',
          'Heartbeat Monitor',
          description: 'Keeps the heartbeat monitor running in the background',
          importance: Importance.low,
        ),
      );

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'heartbeat_bg_channel',
      initialNotificationTitle: 'Vault Heartbeat Active',
      initialNotificationContent: 'Monitoring your check-in timer…',
      foregroundServiceNotificationId: 9999,
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onBackgroundServiceStart,
    ),
  );
}

/// Persist the next-due DateTime so the isolate can read it.
Future<void> saveNextDueToPrefs(DateTime nextDue) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kNextDueKey, nextDue.toIso8601String());
  await prefs.setBool(_kAlarmActiveKey, false);
}

/// Remove the next-due DateTime (user disabled the switch).
Future<void> clearNextDue() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kNextDueKey);
  await prefs.setBool(_kAlarmActiveKey, false);
}

/// Start background monitoring.
Future<void> startHeartbeatMonitor() async {
  final service = FlutterBackgroundService();
  if (!await service.isRunning()) {
    await service.startService();
  }
}

/// Stop background monitoring.
Future<void> stopHeartbeatMonitor() async {
  FlutterBackgroundService().invoke('stop');
}

/// Call after successful check-in to silence the alarm.
Future<void> dismissAlarm() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kAlarmActiveKey, false);
  FlutterBackgroundService().invoke('dismiss_alarm');
}

// ─────────────────────────────────────────────────────────────────────────────
// Background isolate entry point
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();
  await flnp.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  // High-importance alarm channel
  await flnp
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'heartbeat_alarm_v3',
          'Vault Heartbeat ALARM',
          description: 'Critical alert when proof-of-life check-in is overdue',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

  final AudioPlayer player = AudioPlayer();
  bool alarmPlaying = false;

  // ── Stop signal ──────────────────────────────────────────────────────────
  service.on('stop').listen((_) async {
    if (alarmPlaying) {
      await player.stop();
      alarmPlaying = false;
    }
    await flnp.cancel(id: 8888);
    await service.stopSelf();
  });

  // ── Dismiss alarm signal (user checked in) ───────────────────────────────
  service.on('dismiss_alarm').listen((_) async {
    if (alarmPlaying) {
      await player.stop();
      alarmPlaying = false;
    }
    await flnp.cancel(id: 8888);
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Vault Heartbeat Active',
        content: 'Monitoring your check-in timer…',
      );
    }
  });

  // ── Main monitoring loop: every 30 seconds ───────────────────────────────
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!await service.isForegroundService()) return;
    }

    final prefs = await SharedPreferences.getInstance();
    final nextDueStr = prefs.getString(_kNextDueKey);
    if (nextDueStr == null) {
      if (alarmPlaying) {
        await player.stop();
        alarmPlaying = false;
        await flnp.cancel(id: 8888);
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Vault Heartbeat Disabled',
            content: 'Monitoring is currently paused.',
          );
        }
      }
      return;
    }

    final nextDue = DateTime.tryParse(nextDueStr);
    if (nextDue == null) return;

    final bool isOverdue = DateTime.now().toUtc().isAfter(nextDue.toUtc());
    final bool alarmAlreadyActive = prefs.getBool(_kAlarmActiveKey) ?? false;

    if (isOverdue && !alarmAlreadyActive) {
      await prefs.setBool(_kAlarmActiveKey, true);

      // Force launch the app to the foreground aggressively via Android Intent
      if (Platform.isAndroid) {
        try {
          const intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.example.vasihat_nama',
            componentName: 'com.example.vasihat_nama.MainActivity',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_BROUGHT_TO_FRONT],
          );
          await intent.launch();
        } catch (e) {
          debugPrint('Failed to launch foreground intent: $e');
        }
      }

      // Show full-screen alarm notification
      await flnp.show(
        id: 8888,
        title: '🚨 VAULT ALARM — Check In NOW',
        body: 'Your Proof of Life timer expired. Open the app immediately!',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'heartbeat_alarm_v3',
            'Vault Heartbeat ALARM',
            channelDescription: 'Critical alert when proof-of-life check-in is overdue',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            ongoing: true,
            autoCancel: false,
            ticker: 'PROOF OF LIFE REQUIRED',
            enableVibration: true,
            vibrationPattern: Int64List.fromList(<int>[0, 800, 300, 800, 300, 800, 300, 1200]),
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('alarm_sound'),
            enableLights: true,
            ledColor: const Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 500,
            ledOffMs: 500,
            styleInformation: const BigTextStyleInformation(
              'Your Proof of Life check-in is OVERDUE.\n\nOpen the app NOW and check in, or your vault items will be released to your nominees.',
              htmlFormatBigText: false,
              contentTitle: '🚨 VAULT ALARM — CHECK IN REQUIRED',
              summaryText: 'Vasihat Nama',
            ),
          ),
        ),
        payload: 'heartbeat_alarm',
      );

      // Loop alarm sound until dismissal
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('alarm_sound.ogg'));
      alarmPlaying = true;

      // Update the foreground status bar notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: '🚨 VAULT ALARM ACTIVE',
          content: 'Open the app and check in immediately!',
        );
      }
    } else if (!isOverdue && alarmPlaying) {
      // Timer was reset externally (user checked in elsewhere)
      await player.stop();
      alarmPlaying = false;
      await flnp.cancel(id: 8888);
      await prefs.setBool(_kAlarmActiveKey, false);
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Vault Heartbeat Active',
          content: 'Monitoring your check-in timer…',
        );
      }
    }
  });
}
