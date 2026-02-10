import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:new_sms_app/services/sms_service.dart';
import 'package:new_sms_app/utils/phone_utils.dart';

class ConversationProvider extends ChangeNotifier with WidgetsBindingObserver {
  final BuildContext context;
  final ScrollController scrollController = ScrollController();
  final TextEditingController controller = TextEditingController();

  late StreamSubscription smsSub;
  final String address;

  bool firstAutoscrollExecuted = false;
  bool shouldAutoscroll = true;

  ConversationProvider({required this.context, required this.address}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    await DatabaseHelper.instance.markAsRead(address);
    _listenIncomingSms();
  }

  void _listenIncomingSms() {
    smsSub = SmsService.smsStream.listen((sms) async {
      final normalized = PhoneUtils.normalize(sms['address'], source: 'stream');

      if (normalized != address) return;

      await DatabaseHelper.instance.insertMessage({
        'address': normalized,
        'body': sms['body'],
        'date': sms['date'],
        'is_mine': sms['is_mine'],
        'is_read': 1,
      });

      notifyListeners();
      _scrollToBottom();
    });
  }

  Future<void> sendMessage({required String address}) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    try {
      await SmsService.sendSms(address, text);
      _scrollToBottom();
      await SmsService().syncSystemMessages();
      _scrollToBottom();
    } catch (e) {
      if (kDebugMode) print("❌ SMS send failed: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool canReply({required String address}) {
    final addr = address;
    return addr.length >= 6 && RegExp(r'^\+?\d+$').hasMatch(addr);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    smsSub.cancel();
    scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // ignore: deprecated_member_use
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
    }
  }
}
