import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_sms_app/app_constants.dart';
import 'package:new_sms_app/data/model/sms_message_model.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:new_sms_app/services/sms_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxProvider with ChangeNotifier {
  bool isDefaultApp = false;
  bool accessGranted = false;
  bool isFirstLoading = false;
  SharedPreferences? prefs;

  String selectedCategory = "All";
  final List<String> categories = ["All", "Personal", "OTP", "Bank", "Offers"];

  bool isLoading = true;
  List<SmsMessageModel> _messages = [];
  List<SmsMessageModel> filtered = [];
  List<SmsMessageModel> get messages => _messages;

  static const MethodChannel platform = MethodChannel('samples.flutter.dev/sms');
  static const EventChannel eventChannel = EventChannel('samples.flutter.dev/smsStream');
  StreamSubscription? _smsSubscription;

  InboxProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _init1();
      _init();
      _listenIncomingSms();
    });
  }

  Future<void> _init1() async {
    await SharedPreferences.getInstance();
    isLoading = true;
    notifyListeners();
    isDefaultApp = await SmsManager().checkIsDefault();
    accessGranted = prefs?.getBool(AppConstants.accessGranted) ?? false;
    prefs?.setBool(AppConstants.isDefaultApp, isDefaultApp);
    isLoading = false;
    notifyListeners();
  }

  Future<void> _init() async {
    isLoading = true;
    await refreshInbox();
    notifyListeners();
    await syncSystemMessages();
  }

  Future<void> setAsDefaultApp() async {
    isFirstLoading = true;
    notifyListeners();
    isDefaultApp = await SmsManager().requestDefaultSmsApp();
    prefs?.setBool(AppConstants.isDefaultApp, isDefaultApp);
    notifyListeners();
    if (isDefaultApp == true) {
      isFirstLoading = true;
      notifyListeners();
      refreshInbox();
      await syncSystemMessages();
      isFirstLoading = false;
      notifyListeners();
    }
  }

  void _listenIncomingSms() {
    _smsSubscription = eventChannel.receiveBroadcastStream().listen((dynamic sms) async {
      if (sms is Map) {
        // insert into DB (ignore duplicates)
        await DatabaseHelper.instance.insertMessage(Map<String, dynamic>.from(sms));
        await refreshInbox();
      }
    });
  }

  void applyFilter({required String newCategory}) {
    selectedCategory = newCategory;
    filtered = selectedCategory == "All" ? _messages : _messages.where((m) => m.category == selectedCategory).toList();
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
    if (!contactStatus.isGranted) contactStatus = await Permission.contacts.request();

    try {
      final List<dynamic> systemSms = await platform.invokeMethod('fetchSystemSms');
      for (var sms in systemSms) {
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
    }
  }

  Future<void> refreshInbox() async {
    List<Map<String, dynamic>> tempMessages = await DatabaseHelper.instance.getMessages();
    final modelMessages = tempMessages.map((e) {
      SmsMessageModel td = SmsMessageModel.fromJson(Map<String, dynamic>.from(e));
      return td;
    }).toList();
    _messages.clear();
    _messages = modelMessages;
    applyFilter(newCategory: selectedCategory);
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }
}
