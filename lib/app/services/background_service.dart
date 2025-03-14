import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:snooper/app/services/presence_notifications.dart';

class BackgroundServiceManager {
  static const MethodChannel _channel = MethodChannel('utilsChannel');
  static const MethodChannel _backgroundChannel =
      MethodChannel('com.app.snooper/background');

  // This callback will be invoked from the native side
  static void _backgroundCallback() {
    // Initialize callback handler
    _backgroundChannel.setMethodCallHandler((call) async {
      if (call.method == 'checkStatusNow') {
        // Call  notification service to check status
        final notificationService = NotificationService();
        await notificationService.initialize();
        await notificationService.checkStatusNow();
        return true;
      }
      return null;
    });
  }

  static Future<bool> startBackgroundService() async {
    try {
      await _channel.invokeMethod('startBackgroundService');

      // Register the background callback
      final callbackHandle =
          PluginUtilities.getCallbackHandle(_backgroundCallback)?.toRawHandle();
      if (callbackHandle != null) {
        await _channel.invokeMethod('registerBackgroundCallback', {
          'callbackHandle': callbackHandle,
        });
      }

      return true;
    } catch (e) {
      print('Failed to start background service: $e');
      return false;
    }
  }

  static Future<bool> stopBackgroundService() async {
    try {
      await _channel.invokeMethod('stopBackgroundService');
      return true;
    } catch (e) {
      print('Failed to stop background service: $e');
      return false;
    }
  }
}
