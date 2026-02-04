import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:new_sms_app/services/sms_service.dart';

class ConversationProvider extends ChangeNotifier with WidgetsBindingObserver {
  final BuildContext context;
  final ScrollController scrollController = ScrollController();
  bool firstAutoscrollExecuted = false;
  bool shouldAutoscroll = true;

  final TextEditingController controller = TextEditingController();
  late StreamSubscription smsSub;

  ConversationProvider({required this.context, required String address}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init(address: address);
    });
  }

  Future<void> _init({required String address}) async {
    _markAsRead(address: address);
    _listenIncomingSms(address: address);
  }

  void _markAsRead({required String address}) async {
    WidgetsBinding.instance.addObserver(this);
    await DatabaseHelper.instance.markAsRead(address);
  }

  void _listenIncomingSms({required String address}) {
    smsSub = SmsService.smsStream.listen((sms) async {
      if (sms['address'] == address) {
        await DatabaseHelper.instance.insertMessage(sms);
        shouldAutoscroll = true;
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> sendMessage({required String address}) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    final msg = {
      'address': address,
      'body': text,
      'date': DateTime.now().millisecondsSinceEpoch,
      'is_mine': 1,
      'is_read': 1,
    };

    await DatabaseHelper.instance.insertMessage(msg);

    try {
      await SmsService.sendSms(address, text);
    } catch (e) {
      if (kDebugMode) print("❌ SMS send failed: $e");
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
      Future.delayed(const Duration(milliseconds: 120), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}
