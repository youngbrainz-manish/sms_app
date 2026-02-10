import 'package:flutter/material.dart';
import 'package:new_sms_app/screens/contact/contact_list_provider.dart';
import 'package:new_sms_app/screens/conversion/conversation_screen.dart';
import 'package:provider/provider.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContactListProvider(context: context),
      child: Consumer<ContactListProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(title: Text("Select Contact")),
            body: SafeArea(
              child: _buildBody(context: context, provider: provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({required BuildContext context, required ContactListProvider provider}) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: provider.searchController,
                  decoration: InputDecoration(
                    hintText: "Search contacts",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: provider.search,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        address: provider.searchController.text.trim(),
                        contactName: provider.searchController.text.trim(),
                        photoUri: null,
                      ),
                    ),
                  );
                },
                child: Icon(Icons.send),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: provider.filtered.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final c = provider.filtered[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: c.avatar != null ? MemoryImage(c.avatar!) : null,
                  child: c.avatar == null ? Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : "?") : null,
                ),
                title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(c.phone),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(address: c.phone, contactName: c.name, photoUri: c.avatar),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
