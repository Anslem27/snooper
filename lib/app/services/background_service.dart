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

  static Future<void> startBackgroundService() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
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
    );

    logger.d('Background service registered to run every minute');
  }

  static Future<void> stopBackgroundService() async {
    await Workmanager().cancelAll();
    logger.d('Background service stopped');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      logger.d('Background task $taskName started');

      final notificationService = NotificationService();
      await notificationService.initialize();

      await notificationService.checkStatusNow();

      logger.d('Background task $taskName completed successfully');
      return Future.value(true);
    } catch (e) {
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

  static Future<void> startForegroundService() async {
    if (_isRunning) return;

    //  notification channel for foreground service
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

    // manual periodic checking
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final notificationService = NotificationService();
      await notificationService.checkStatusNow();
    });

    _isRunning = true;
    logger.d('Foreground service started');
  }

  static Future<void> stopForegroundService() async {
    if (!_isRunning) return;

    _timer?.cancel();
    _timer = null;

    await _notificationsPlugin.cancel(9999);

    _isRunning = false;
    logger.d('Foreground service stopped');
  }
}
