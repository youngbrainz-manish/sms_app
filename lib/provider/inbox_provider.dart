import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:new_sms_app/app_constants.dart';
import 'package:new_sms_app/data/model/contact_model.dart';
import 'package:new_sms_app/data/model/sms_message_model.dart';
import 'package:new_sms_app/database/contacts_database_helper.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:new_sms_app/services/sms_manager.dart';
import 'package:new_sms_app/services/sms_service.dart';
import 'package:new_sms_app/utils/phone_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxProvider with ChangeNotifier {
  bool isDefaultApp = false;
  bool accessGranted = false;
  SharedPreferences? prefs;

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
    await syncContactsSilently(); // Then enrich inbox with contacts
    notifyListeners();
    if (messages.isEmpty) {
      isLoading = true;
      notifyListeners();
    }
    await syncSystemMessages();
  }

  Future<void> setAsDefaultApp() async {
    notifyListeners();
    isDefaultApp = await SmsManager().requestDefaultSmsApp();
    prefs?.setBool(AppConstants.isDefaultApp, isDefaultApp);
    notifyListeners();
    if (isDefaultApp == true) {
      notifyListeners();
      refreshInbox();
      await syncSystemMessages();
      notifyListeners();
    }
  }

  void _listenIncomingSms() {
    _smsSubscription = eventChannel.receiveBroadcastStream().listen((dynamic sms) async {
      if (sms is Map) {
        await DatabaseHelper.instance.insertMessage({
          'address': PhoneUtils.normalize(sms['address'], source: '4'),
          'body': sms['body'].toString(),
          'date': sms['date'],
          'is_mine': sms['is_mine'],
          'is_read': sms['is_read'],
        });
        await refreshInbox();
      }
    });
  }

  Future<void> syncSystemMessages() async {
    var contactStatus = await Permission.contacts.status;
    if (!contactStatus.isGranted) contactStatus = await Permission.contacts.request();

    try {
      await SmsService().syncSystemMessages();
      await refreshInbox();

      await syncContactsSilently(); // 👈 important
    } on PlatformException catch (e) {
      debugPrint("Sync error: ${e.message}");
    }
  }

  Future<void> refreshInbox() async {
    List<Map<String, dynamic>> tempMessages = await DatabaseHelper.instance.getInboxWithContacts();
    final modelMessages = tempMessages.map((e) {
      SmsMessageModel td = SmsMessageModel.fromJson(Map<String, dynamic>.from(e));
      return td;
    }).toList();
    _messages.clear();
    _messages = modelMessages;
    filtered = _messages;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> syncContactsSilently() async {
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true, withThumbnail: true);

      final List<ContactModel> contactModels = [];

      for (final contact in contacts) {
        if (contact.phones.isEmpty) continue;

        for (final phone in contact.phones) {
          final normalizedPhone = PhoneUtils.normalize(phone.number, source: 'contact_sync');
          contactModels.add(
            ContactModel(
              id: contact.id,
              name: contact.displayName,
              phone: normalizedPhone,
              avatar: contact.photo ?? contact.thumbnail,
            ),
          );
        }
      }

      // 🔥 STORE ALL CONTACTS IN DB (BATCH)
      await ContactsDatabaseHelper.instance.insertContacts(contactModels);

      // 🔄 REFRESH INBOX (this updates UI)
      await refreshInbox();
    } catch (e) {
      debugPrint('Contact sync error: $e');
    }
  }
}
