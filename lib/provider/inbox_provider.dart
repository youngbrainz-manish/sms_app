// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:new_sms_app/database/database_helper.dart';
// import 'package:permission_handler/permission_handler.dart';

// class InboxProvider with ChangeNotifier {
//   String selectedCategory = "All";
//   final List<String> categories = ["All", "Personal", "OTP", "Bank", "Offers"];

//   bool isLoading = false;
//   List<Map<String, dynamic>> _messages = [];
//   List<Map<String, dynamic>> filtered = [];
//   List<Map<String, dynamic>> get messages => _messages;

//   static const platform = MethodChannel('samples.flutter.dev/sms');

//   InboxProvider() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _init();
//     });
//   }

//   Future<void> _init() async {
//     isLoading = true;
//     notifyListeners();

//     await refreshInbox();
//     if (_messages.isEmpty) {
//       await syncSystemMessages();
//     }

//     applyFilter(newCategory: "All");
//   }

//   applyFilter({required String newCategory}) {
//     selectedCategory = newCategory;
//     filtered = selectedCategory == "All"
//         ? _messages
//         : _messages.where((m) => m['category'] == selectedCategory).toList();
//     isLoading = false;
//     notifyListeners();
//   }

//   String _determineCategory(String address, String body) {
//     final b = body.toLowerCase();
//     final addr = address.toLowerCase();
//     if (RegExp(r'otp|code|verify|vcode').hasMatch(b)) return "OTP";
//     if (RegExp(r'bank|credit|debit|txn|amt').hasMatch(b)) return "Bank";
//     if (addr.length <= 6 || !addr.contains('+')) return "Offers";
//     return "Personal";
//   }

//   Future<void> syncSystemMessages() async {
//     var contactStatus = await Permission.contacts.status;
//     if (!contactStatus.isGranted) {
//       contactStatus = await Permission.contacts.request();
//     }

//     try {
//       final List<dynamic> systemSms = await platform.invokeMethod('fetchSystemSms');
//       print("object route from system first => ${systemSms.first}");
//       for (var sms in systemSms) {
//         await DatabaseHelper.instance.insertMessage({
//           'address': sms['address'],
//           'body': sms['body'],
//           'date': sms['date'],
//           'is_mine': sms['is_mine'],
//           'is_read': sms['is_read'],
//           'category': _determineCategory(sms['address'], sms['body']),
//         });
//       }

//       await refreshInbox();
//     } on PlatformException catch (e) {
//       debugPrint("Sync error: ${e.message}");
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> refreshInbox() async {
//     _messages = await DatabaseHelper.instance.getMessages();
//     print("object route from database first => ${_messages.first}");

//     applyFilter(newCategory: selectedCategory);
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class InboxProvider with ChangeNotifier {
  String selectedCategory = "All";
  final List<String> categories = ["All", "Personal", "OTP", "Bank", "Offers"];

  bool isLoading = false;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> filtered = [];

  List<Map<String, dynamic>> get messages => filtered;

  static const platform = MethodChannel('samples.flutter.dev/sms');

  InboxProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    isLoading = true;
    notifyListeners();
    await refreshInbox();
    if (_messages.isEmpty) {
      isLoading = true;
      notifyListeners();
      await syncSystemMessages();
    }

    applyFilter(newCategory: "All");
  }

  void applyFilter({required String newCategory}) {
    selectedCategory = newCategory;

    filtered = selectedCategory == "All"
        ? _messages
        : _messages.where((m) => m['category'] == selectedCategory).toList();

    isLoading = false;
    notifyListeners();
  }

  String _determineCategory(String address, String body) {
    final b = body.toLowerCase();
    final addr = address.toLowerCase();

    if (RegExp(r'otp|code|verify|vcode').hasMatch(b)) return "OTP";
    if (RegExp(r'bank|credit|debit|txn|amt').hasMatch(b)) return "Bank";
    if (addr.length <= 6 || !addr.contains('+')) return "Offers";
    return "Personal";
  }

  Future<void> syncSystemMessages() async {
    var contactStatus = await Permission.contacts.status;
    if (!contactStatus.isGranted) {
      contactStatus = await Permission.contacts.request();
    }

    try {
      final List<dynamic> systemSms = await platform.invokeMethod('fetchSystemSms');

      // ✅ SORT BY DATE DESC
      systemSms.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));
      if (systemSms.isNotEmpty) {
        print("Inbox first 1=> ${systemSms.first}");
      }
      for (final sms in systemSms) {
        await DatabaseHelper.instance.insertMessage({
          'address': sms['address'],
          'body': sms['body'],
          'date': sms['date'],
          'is_mine': sms['is_mine'],
          'is_read': sms['is_read'],
          'category': _determineCategory(sms['address'], sms['body']),
        });
      }

      await refreshInbox();
    } on PlatformException catch (e) {
      debugPrint("Sync error: ${e.message}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshInbox() async {
    _messages = await DatabaseHelper.instance.getMessages();

    if (_messages.isNotEmpty) {
      print("Inbox first => ${_messages.first}");
    }

    applyFilter(newCategory: selectedCategory);
  }
}
