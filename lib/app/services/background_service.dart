import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:snooper/app/services/presence_notifications.dart';
import 'package:snooper/app/screens/home.dart';

class BackgroundServiceManager {
  static const String workManagerTaskName = 'snooperBackgroundChecks';
  static const Duration checkInterval = Duration(minutes: 1);
  static final FlutterLocalNotificationsPlugin _debugNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeDebugNotifications() async {
    const initSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_name');
    const initSettingsIOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _debugNotifications.initialize(initSettings);
  }

  static Future<void> showDebugNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'debug_notifications',
      'Debug Notifications',
      channelDescription: 'Notifications for debugging service execution',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_name',
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final id = DateTime.now().millisecondsSinceEpoch % 10000;
    await _debugNotifications.show(id, title, body, details);
  }

  static Future<void> startBackgroundService() async {
    await initializeDebugNotifications();
    await showDebugNotification(
        'Background Service', 'Attempting to register background task');

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    await Workmanager().registerPeriodicTask(
      'snooperStatusCheck',
      workManagerTaskName,
      frequency: checkInterval,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      initialDelay: Duration(seconds: 10),
    );

    await showDebugNotification(
        'Background Service', 'Task registered successfully');
    logger.d('Background service registered to run every minute');
  }

  static Future<void> stopBackgroundService() async {
    await Workmanager().cancelAll();
    await showDebugNotification('Background Service', 'Tasks cancelled');
    logger.d('Background service stopped');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      // Initialize debug notifications inside the callback
      await BackgroundServiceManager.initializeDebugNotifications();
      await BackgroundServiceManager.showDebugNotification(
          'Background Task Running',
          'Task $taskName started at ${DateTime.now().toString()}');

      logger.d('Background task $taskName started');

      final notificationService = NotificationService();
      await notificationService.initialize();

      await notificationService.checkStatusNow();

      await BackgroundServiceManager.showDebugNotification(
          'Background Task Complete',
          'Task $taskName completed at ${DateTime.now().toString()}');

      logger.d('Background task $taskName completed successfully');
      return Future.value(true);
    } catch (e) {
      await BackgroundServiceManager.initializeDebugNotifications();
      await BackgroundServiceManager.showDebugNotification(
          'Background Task Failed', 'Error: $e');

      logger.e('Background task $taskName failed: $e');
      return Future.value(false);
    }
  });
}

class ForegroundServiceManager {
  static bool _isRunning = false;
  static Timer? _timer;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // static int _debugCounter = 0;

  static Future<void> startForegroundService() async {
    if (_isRunning) return;

    // Initialize and show debug notification
    await BackgroundServiceManager.initializeDebugNotifications();
    await BackgroundServiceManager.showDebugNotification(
        'Foreground Service', 'Starting foreground service');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'snooper_foreground_service',
      'Snooper Service',
      channelDescription: 'Keeps Snooper running in the background',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Show foreground notification
    await _notificationsPlugin.show(
      9999,
      'Snooper is running',
      'Monitoring your friends\' activities',
      notificationDetails,
    );

    // Manual periodic checking
    // _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
    //   try {
    //     _debugCounter++;
    //     await BackgroundServiceManager.showDebugNotification(
    //         'Foreground Timer Tick',
    //         'Count: $_debugCounter - ${DateTime.now().toString()}');

    //     final notificationService = NotificationService();
    //     await notificationService.checkStatusNow();
    //   } catch (e) {
    //     await BackgroundServiceManager.showDebugNotification(
    //         'Foreground Timer Error', 'Error: $e');
    //   }
    // });

    _isRunning = true;
    logger.d('Foreground service started');
  }

  static Future<void> stopForegroundService() async {
    if (!_isRunning) return;

    _timer?.cancel();
    _timer = null;

    await _notificationsPlugin.cancel(9999);

    await BackgroundServiceManager.showDebugNotification(
        'Foreground Service', 'Foreground service stopped');

    _isRunning = false;
    logger.d('Foreground service stopped');
  }
}
