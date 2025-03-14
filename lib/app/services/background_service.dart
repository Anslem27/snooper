import 'package:flutter/services.dart';

class BackgroundServiceManager {
  static const MethodChannel _channel = MethodChannel('utilsChannel');

  static Future<bool> startBackgroundService() async {
    try {
      await _channel.invokeMethod('startBackgroundService');
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
