import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmsService {
  static const platform = MethodChannel('samples.flutter.dev/sms');

  static Future<bool?> sendSms(String phone, String message) async {
    try {
      await platform.invokeMethod('sendSms', {
        'to': phone, // ✅ MUST MATCH Kotlin
        'message': message, // ✅ MUST MATCH Kotlin
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } on PlatformException catch (e) {
      debugPrint("Failed to send SMS: '${e.message}'.  :: $phone :: $message");
      return false;
    }
  }
}
