import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:new_sms_app/utils/phone_utils.dart';

class SmsService {
  static const MethodChannel _platform = MethodChannel('samples.flutter.dev/sms');

  static const EventChannel _eventChannel = EventChannel('samples.flutter.dev/smsStream');

  /// Send SMS (outgoing only)
  static Future<bool> sendSms(String phone, String message) async {
    try {
      await _platform.invokeMethod('sendSms', {'to': phone, 'message': message});
      return true;
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to send SMS: ${e.message}');
      return false;
    }
  }

  /// Incoming SMS stream (UI refresh trigger)
  static Stream<Map<String, dynamic>> get smsStream {
    return _eventChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event));
  }

  Future<void> syncSystemMessages() async {
    final List<dynamic> systemSms = await MethodChannel('samples.flutter.dev/sms').invokeMethod('fetchSystemSms');
    for (var sms in systemSms) {
      await DatabaseHelper.instance.insertMessage({
        'address': PhoneUtils.normalize(sms['address'], source: '5'),
        'body': sms['body'].toString(),
        'date': sms['date'],
        'is_mine': sms['is_mine'],
        'is_read': sms['is_read'],
      });
    }
  }
}
