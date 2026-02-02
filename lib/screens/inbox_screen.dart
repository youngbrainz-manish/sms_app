import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_sms_app/provider/inbox_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

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
            appBar: AppBar(
              title: const Text(
                "Messages",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              actions: [
                IconButton(
                  onPressed: () async {
                    provider.syncSystemMessages();
                  },
                  icon: Icon(Icons.refresh),
                ),
              ],
            ),
            body: _buildBody(provider: provider),
          );
        },
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
                    _buildCategoryBar(provider: provider),
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
                                return _buildConversationTile(provider.filtered[index]);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar({required InboxProvider provider}) {
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: provider.categories
            .map(
              (cat) => GestureDetector(
                onTap: () => provider.applyFilter(newCategory: cat),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  margin: EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: provider.selectedCategory == cat ? Colors.indigo : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.indigo),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: provider.selectedCategory == cat ? Colors.white : Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> msg) {
    final name = msg['contact_name'] ?? msg['address'];
    final bool isUnread = msg['is_read'] == 0;

    return GestureDetector(
      onTap: () {
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationScreen(address: sms['address'])));
      },
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 6, right: 4),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: msg['photo_uri'] != null ? FileImage(File(msg['photo_uri'])) : null,
          child: msg['photo_uri'] == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : "NA") : null,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(msg['body'], maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          children: [
            isUnread
                ? Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: Color(0xFF4A3AFF), shape: BoxShape.circle),
                    child: const Text(
                      "1",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : SizedBox(),
            Text(_formatDate(msg['date']), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final dateFormat = DateFormat('hh:mm a');
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return dateFormat.format(date);
  }
}
