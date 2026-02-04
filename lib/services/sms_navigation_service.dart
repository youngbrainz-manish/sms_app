import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_sms_app/screens/conversion/conversation_screen.dart';

class SmsNavigationService {
  static const MethodChannel _channel = MethodChannel('sms_navigation');

  static void init(BuildContext context) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openConversation') {
        final String address = call.arguments['address'];
        Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationScreen(address: address)));
      }
    });
  }
}
