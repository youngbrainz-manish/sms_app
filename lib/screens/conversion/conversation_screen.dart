import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_sms_app/database/database_helper.dart';
import 'package:new_sms_app/screens/conversion/conversation_provider.dart';
import 'package:provider/provider.dart';

class ConversationScreen extends StatefulWidget {
  final String address;
  final String? contactName;
  final Uint8List? photoUri;

  const ConversationScreen({super.key, required this.address, this.contactName, this.photoUri});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConversationProvider(context: context, address: widget.address),
      child: Consumer<ConversationProvider>(
        builder: (context, provider, child) {
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                titleSpacing: 0,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.photoUri != null ? MemoryImage(widget.photoUri!) : null,
                      child: widget.photoUri == null
                          ? Text((widget.contactName ?? widget.address).characters.first.toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.contactName ?? widget.address, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              body: _buildBody(provider: provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({required ConversationProvider provider}) {
    return Column(
      children: [
        Expanded(child: _messagesList(provider: provider)),
        provider.canReply(address: widget.address)
            ? _inputBar(provider: provider)
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade300,
                child: const Center(
                  child: Text("The sender does not support replies", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
      ],
    );
  }

  Widget _messagesList({required ConversationProvider provider}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseHelper.instance.conversationStream(widget.address),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        if (provider.firstAutoscrollExecuted == false || provider.shouldAutoscroll == true) {
          provider.firstAutoscrollExecuted = true;
          provider.shouldAutoscroll = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.scrollController.hasClients) {
              provider.scrollController.jumpTo(provider.scrollController.position.maxScrollExtent);
            }
          });
        }

        return ListView.separated(
          controller: provider.scrollController,
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            // ignore: deprecated_member_use
            MediaQuery.of(context).viewInsets.bottom + (WidgetsBinding.instance.window.viewInsets.bottom > 0 ? 42 : 12),
          ),

          physics: const BouncingScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (_, index) {
            final msg = messages[index];
            return _MessageBubble(body: msg['body'], date: msg['date'], isMine: msg['is_mine'] == 1);
          },
          separatorBuilder: (context, index) {
            final currentDate = DateTime.fromMillisecondsSinceEpoch(messages[index]['date']).toLocal();

            final nextDate = DateTime.fromMillisecondsSinceEpoch(messages[index + 1]['date']).toLocal();

            final isNewDay = isNewDate(current: nextDate, previous: currentDate);

            if (isNewDay) {
              return Row(
                children: [
                  const Expanded(child: Divider(color: Colors.orange)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      DateFormat('EEE, d MMM y').format(nextDate),
                      style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.orange)),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _inputBar({required ConversationProvider provider}) {
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
              controller: provider.controller,
              decoration: InputDecoration(
                hintText: "Type message…",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              provider.sendMessage(address: widget.address);
            },
            child: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool isNewDate({DateTime? current, DateTime? previous}) {
    if (current == null) return false;
    if (previous == null) return true;
    return current.year != previous.year || current.month != previous.month || current.day != previous.day;
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
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: isMine ? Colors.indigo : Colors.grey.shade400,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomLeft: isMine ? Radius.circular(8) : Radius.circular(0),
                bottomRight: isMine ? Radius.circular(0) : Radius.circular(8),
              ),
            ),
            child: Text(
              body,
              style: TextStyle(color: isMine ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }
}
