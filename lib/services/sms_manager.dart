import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmsManager {
  static const platform = MethodChannel('samples.flutter.dev/sms');

  Future<bool> requestDefaultSmsApp() async {
    try {
      final bool result = await platform.invokeMethod('requestDefaultSms');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to request default SMS app: ${e.message}");
      return false;
    }
  }

  Future<bool> checkIsDefault() async {
    final bool isDefault = await platform.invokeMethod('isDefaultSmsApp');
    return isDefault;
  }
}
