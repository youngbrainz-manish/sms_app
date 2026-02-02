import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SmsManager {
  static const platform = MethodChannel('samples.flutter.dev/sms');

  Future<bool?> requestDefaultSmsApp() async {
    bool retval = false;
    try {
      final dynamic result = await platform.invokeMethod('requestDefaultSms');

      if (result == "Already Default") {
        debugPrint("route User is already using this app as default.");
        retval = true;
      } else if (result == true) {
        debugPrint("route Popup showed successfully.");
        retval = true;
      }
    } on PlatformException catch (e) {
      debugPrint("route System failed to show popup: ${e.message}");
      retval = false;
    }
    return retval;
  }

  Future<bool> checkIsDefault() async {
    final bool isDefault = await platform.invokeMethod('isDefaultSmsApp');
    return isDefault;
  }
}
