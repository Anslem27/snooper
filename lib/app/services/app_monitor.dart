import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home.dart';

class AppMonitorService {
  static const MethodChannel _channel = MethodChannel('utilsChannel');
  static final StreamController<AppActivityInfo> _appDetectionController =
      StreamController<AppActivityInfo>.broadcast();

  static Stream<AppActivityInfo> get appDetections =>
      _appDetectionController.stream;

  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool shouldMonitor = prefs.getBool('app_monitor_enabled') ?? false;

    if (shouldMonitor) {
      startMonitoring();
    }
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppDetected':
        final Map<String, dynamic> args =
            Map<String, dynamic>.from(call.arguments);
        final appInfo = AppActivityInfo(
          packageName: args['packageName'],
          appName: args['appName'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(args['timestamp']),
        );

        // logger.d('App detected: ${appInfo.appName} (${appInfo.packageName})');
        _appDetectionController.add(appInfo);

        await _storeAppActivity(appInfo);
        break;
      default:
        logger.w('Unknown method call: ${call.method}');
    }
    return null;
  }

  static Future<void> _storeAppActivity(AppActivityInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> activities = prefs.getStringList('recent_activities') ?? [];

    // new activity in format: packageName|appName|timestamp
    String activityStr =
        '${info.packageName}|${info.appName}|${info.timestamp.millisecondsSinceEpoch}';
    activities.insert(0, activityStr);

    // Keep only the last 100 activities
    if (activities.length > 100) {
      activities = activities.sublist(0, 100);
    }

    await prefs.setStringList('recent_activities', activities);
  }

  static Future<bool> startMonitoring() async {
    try {
      final bool result = await _channel.invokeMethod('startAppMonitorService');

      if (result) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('app_monitor_enabled', true);
        logger.i('App monitoring service started');
      } else {
        logger.w('App monitoring service failed to start. Permission issue?');
      }

      return result;
    } catch (e) {
      logger.e('Error starting app monitoring service: $e');
      return false;
    }
  }

  static Future<bool> stopMonitoring() async {
    try {
      final bool result = await _channel.invokeMethod('stopAppMonitorService');

      if (result) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('app_monitor_enabled', false);
        logger.i('App monitoring service stopped');
      }

      return result;
    } catch (e) {
      logger.e('Error stopping app monitoring service: $e');
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    try {
      return await _channel.invokeMethod('checkUsageStatsPermission');
    } catch (e) {
      logger.e('Error checking permission: $e');
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      logger.e('Error requesting permission: $e');
    }
  }

  static Future<List<AppActivityInfo>> getStoredActivities() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> activities = prefs.getStringList('recent_activities') ?? [];

    return activities.map((activityStr) {
      final parts = activityStr.split('|');
      return AppActivityInfo(
        packageName: parts[0],
        appName: parts[1],
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2])),
      );
    }).toList();
  }

  // Clean up resources
  static void dispose() {
    _appDetectionController.close();
  }
}

class AppActivityInfo {
  final String packageName;
  final String appName;
  final DateTime timestamp;

  AppActivityInfo(
      {required this.packageName,
      required this.appName,
      required this.timestamp});

  @override
  String toString() =>
      'AppActivityInfo(packageName: $packageName, appName: $appName, timestamp: $timestamp)';
}
