import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:snooper/app/screens/home.dart';

class NativeCalls<T> {
  static MethodChannel get methodChannel => const MethodChannel('utilsChannel');

  Future<void> showNativeAndroidToast(String data, int duration) async {
    try {
      await methodChannel.invokeMethod(
        'showNativeAndroidToast',
        <String, dynamic>{'message': data, 'duration': duration},
      );
    } catch (e) {
      if (kDebugMode) logger.t(e.toString());
    }
  }
}
