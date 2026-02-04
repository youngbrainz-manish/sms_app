import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmsService {
  static const platform = MethodChannel('samples.flutter.dev/sms');

  static Future<bool?> sendSms(String phone, String message) async {
    try {
      await platform.invokeMethod('sendSms', {'to': phone, 'message': message});
      return true;
    } on PlatformException catch (e) {
      debugPrint("Failed to send SMS: ${e.message}");
      return false;
    }
  }

  static const EventChannel _eventChannel = EventChannel('samples.flutter.dev/smsStream');

  static Stream<Map<String, dynamic>> get smsStream =>
      _eventChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event));
}
