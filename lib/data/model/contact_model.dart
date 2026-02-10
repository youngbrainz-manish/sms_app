import 'dart:typed_data';

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final Uint8List? avatar;

  ContactModel({required this.id, required this.name, required this.phone, this.avatar});
}
