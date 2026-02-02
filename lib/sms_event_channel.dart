// import 'package:flutter/services.dart';

// class SmsEventChannel {
//   static const EventChannel _eventChannel = EventChannel('sms_receiver');

//   static Stream<Map<String, dynamic>>? _smsStream;

//   static Stream<Map<String, dynamic>> get smsStream {
//     _smsStream ??= _eventChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event as Map));
//     return _smsStream!;
//   }
// }
