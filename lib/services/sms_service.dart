import 'package:flutter/services.dart';

class SmsService {
  static const platform = MethodChannel('samples.flutter.dev/sms');

  static Future<void> sendSms(String phone, String message) async {
    try {
      await platform.invokeMethod('sendSms', {'phone': phone, 'msg': message});
    } on PlatformException catch (e) {
      print("Failed to send SMS: '${e.message}'.");
    }
  }
}
