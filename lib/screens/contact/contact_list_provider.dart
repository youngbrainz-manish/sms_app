import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:new_sms_app/data/model/contact_model.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactListProvider extends ChangeNotifier {
  final BuildContext context;

  bool isLoading = true;
  List<ContactModel> contacts = [];
  List<ContactModel> filtered = [];

  TextEditingController searchController = TextEditingController();

  ContactListProvider({required this.context}) {
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    isLoading = true;
    notifyListeners();

    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        isLoading = false;
        notifyListeners();
        return;
      }
    }

    final rawContacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true);

    contacts = rawContacts.where((c) => c.phones.isNotEmpty).map((c) {
      return ContactModel(
        id: c.id,
        name: c.displayName,
        phone: c.phones.first.number.replaceAll(' ', ''),
        avatar: c.photo,
      );
    }).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    filtered = contacts;
    isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      filtered = contacts;
    } else {
      filtered = contacts.where((c) {
        return c.name.toLowerCase().contains(query.toLowerCase()) || c.phone.contains(query);
      }).toList();
    }
    notifyListeners();
  }
}
