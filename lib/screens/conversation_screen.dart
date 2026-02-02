import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:new_sms_app/services/sms_service.dart';

class ConversationScreen extends StatefulWidget {
  final String address;
  final String? contactName;
  final String? photoUri;

  const ConversationScreen({super.key, required this.address, this.contactName, this.photoUri});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    _messages = await DatabaseHelper.instance.getConversation(widget.address);

    // mark messages as read (optional – future use)
    // await DatabaseHelper.instance.markAsRead(widget.address);

    setState(() => _loading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  bool get _canReply {
    final addr = widget.address;
    if (addr.length >= 6 && (RegExp(r'^\+?\d+$').hasMatch(addr))) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.photoUri != null ? NetworkImage(widget.photoUri!) : null,
              child: widget.photoUri == null
                  ? Text((widget.contactName ?? widget.address).characters.first.toUpperCase())
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.contactName ?? widget.address, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      final isMine = msg['is_mine'] == 1;
                      return _MessageBubble(body: msg['body'], date: msg['date'], isMine: isMine);
                    },
                    separatorBuilder: (context, index) {
                      if (index > 1) {
                        bool? data = isNewDate(
                          current: DateTime.fromMillisecondsSinceEpoch(_messages[index]['date']),
                          previous: DateTime.fromMillisecondsSinceEpoch(_messages[index - 1]['date']),
                        );
                        if (data == true) {
                          return Row(
                            children: [
                              Expanded(child: Divider(color: Colors.red)),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade300,
                                ),
                                child: Text(
                                  _messages[index]['date'] != null
                                      ? DateFormat('EEE, d/M/y').format(
                                          DateTime.fromMillisecondsSinceEpoch(_messages[index]['date']).toLocal(),
                                        )
                                      : '',
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.red)),
                            ],
                          );
                        }
                      }
                      return SizedBox();
                    },
                  ),
                ),

                if (!_canReply)
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Center(
                      child: Text(
                        "The Sender does not support replies",
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  _inputBar(), // normal input bar for replyable senders
              ],
            ),
    );
  }

  bool isNewDate({DateTime? current, DateTime? previous}) {
    if (current == null) return false;
    if (previous == null) return true; // first item
    return current.year != previous.year || current.month != previous.month || current.day != previous.day;
  }

  _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type message…",
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              _sendMessage();
            },
            child: CircleAvatar(
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      // Optimistic update
      Map<String, dynamic> newMessage = {
        'address': widget.address,
        'body': text,
        'date': DateTime.now().millisecondsSinceEpoch,
        'is_mine': 1,
        'is_read': 1,
        'category': 'Personal',
      };
      await DatabaseHelper.instance.insertMessage(newMessage);
      print("object route => $newMessage");
      _messages = [newMessage, ..._messages];
      setState(() {});

      try {
        var dat = await SmsService.sendSms(widget.address, text);

        if (kDebugMode) {
          print("object route => dat => $dat");
        }
        // // return true;
        // _controller.clear();
      } catch (e) {
        if (kDebugMode) print("Error Send Message => $e");
        // return false;
      }

      // Wait a bit for the message to be written to SMS database
      // await Future.delayed(const Duration(milliseconds: 1500));
      // Reload to get the actual message from system
      await _loadConversation();
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      // emit(ChatError(e.toString()));
      // await loadConversation(address, silent: true);
    }
    // return true;
    _controller.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final String body;
  final int date;
  final bool isMine;

  const _MessageBubble({required this.body, required this.date, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(date));

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMine ? Colors.indigo.shade400 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(body, style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 15)),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isMine ? 0 : 4.0, right: isMine ? 4.0 : 0),
            child: Text(time, style: TextStyle(fontSize: 11, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
