import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:new_sms_app/data/model/sms_message_model.dart';
import 'package:new_sms_app/provider/inbox_provider.dart';
import 'package:new_sms_app/screens/contact/contact_list_screen.dart';
import 'package:new_sms_app/screens/conversion/conversation_screen.dart';
import 'package:provider/provider.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InboxProvider(),
      child: Consumer<InboxProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(provider),
            body: provider.isDefaultApp && provider.isFirstLoading == false
                ? _buildBody(provider: provider)
                : getDefaultPermissionWidget(provider: provider),
            floatingActionButton: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ContactListScreen()));
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black38, width: 2),
                ),
                child: Icon(Icons.edit),
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(InboxProvider provider) {
    return AppBar(
      centerTitle: true,
      title: const Text(
        "Messages",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      actions: (provider.isDefaultApp == true)
          ? [
              IconButton(
                onPressed: () async {
                  provider.syncSystemMessages();
                },
                icon: Icon(Icons.refresh),
              ),
            ]
          : [],
    );
  }

  Widget getDefaultPermissionWidget({required InboxProvider provider}) {
    return Center(
      child: Column(
        children: [
          if (provider.isDefaultApp == false) ...[
            Image.asset("assets/images/default_icon.png"),
            Text("data"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                provider.setAsDefaultApp();
              },
              child: Text("Set as Default SMS App"),
            ),
          ] else ...[
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 20,
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Text(
                          "APP LOGO",
                          style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Lottie.asset('assets/lottie/setting.json'),
                  Padding(
                    padding: const EdgeInsets.only(top: 60, left: 18),
                    child: Text(
                      "Loading...",
                      style: TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Positioned(
                    bottom: 100,
                    child: Text(
                      "Loading Messages...",
                      style: TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody({required InboxProvider provider}) {
    return Column(
      children: [
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: provider.filtered.isEmpty
                          ? Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  provider.syncSystemMessages();
                                },
                                child: Icon(Icons.refresh),
                              ),
                            )
                          : ListView.separated(
                              itemCount: provider.filtered.length,
                              separatorBuilder: (context, i) => const Divider(indent: 85, height: 1),
                              itemBuilder: (context, index) {
                                return _buildConversationTile(msg: provider.filtered[index], provider: provider);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildConversationTile({required SmsMessageModel msg, required InboxProvider provider}) {
    final name = msg.name ?? msg.address;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConversationScreen(address: msg.address ?? '', contactName: name, photoUri: msg.avatar),
          ),
        );
        await provider.refreshInbox();
      },
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 6, right: 4),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: msg.avatar != null ? MemoryImage(msg.avatar!) : null,
          child: msg.avatar == null
              ? Text((name ?? '').isNotEmpty ? name!.characters.first[0].toUpperCase() : "NA")
              : null,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(msg.body ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          children: [
            msg.isRead == false
                ? Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: Color(0xFF4A3AFF), shape: BoxShape.circle),
                    child: Text(
                      msg.unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Text(""),
            Text(_formatDate(msg.date ?? 0), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
