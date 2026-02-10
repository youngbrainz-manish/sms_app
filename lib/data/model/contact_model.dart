import 'dart:typed_data';

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final Uint8List? avatar;

  const ContactModel({required this.id, required this.name, required this.phone, this.avatar});

  /// ---------------- COPY WITH ----------------
  ContactModel copyWith({String? id, String? name, String? phone, Uint8List? avatar}) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
    );
  }

  /// ---------------- TO JSON (SQLite) ----------------
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'avatar': avatar};
  }

  /// ---------------- FROM JSON (SQLite) ----------------
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] is Uint8List ? json['avatar'] as Uint8List : null,
    );
  }

  /// ---------------- EQUALITY ----------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id && other.phone == phone;
  }

  @override
  int get hashCode => id.hashCode ^ phone.hashCode;

  @override
  String toString() {
    return 'ContactModel(id: $id, name: $name, phone: $phone)';
  }
}
