import 'dart:typed_data';

class SmsMessageModel {
  final int? id;
  final Uint8List? avatar;
  final String? name;
  final String? address;
  final String? body;
  final DateTime? date;
  final bool? isMine;
  final bool? isRead;
  final String? category;

  SmsMessageModel({
    this.id,
    this.avatar,
    this.name,
    this.address,
    this.body,
    this.date,
    this.isMine,
    this.isRead,
    this.category,
  });

  /// 🔹 FROM SYSTEM SMS (Android)
  factory SmsMessageModel.fromSystemMap(Map<String, dynamic> map) {
    return SmsMessageModel(
      id: map['id'] as int?,
      address: map['address'] as String?,
      body: map['body'] as String?,
      date: map['date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['date']) : null,

      // 🔥 int → bool conversion
      isMine: map['is_mine'] == 1,
      isRead: map['is_read'] == 1,

      // Contact info
      name: map['contact_name'] as String?,
      category: map['category'] as String?,

      // avatar not available yet
      avatar: null,
    );
  }

  /// 🔹 NORMAL JSON (local DB / API)
  factory SmsMessageModel.fromJson(Map<String, dynamic> json) {
    return SmsMessageModel(
      id: json['id'],
      avatar: json['avatar'],
      name: json['name'],
      address: json['address'],
      body: json['body'],
      date: json['date'] != null ? DateTime.fromMillisecondsSinceEpoch(json['date']) : null,
      isMine: json['isMine'],
      isRead: json['isRead'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar': avatar,
      'name': name,
      'address': address,
      'body': body,
      'date': date?.millisecondsSinceEpoch,
      'isMine': isMine,
      'isRead': isRead,
      'category': category,
    };
  }

  @override
  String toString() {
    return 'SmsMessageModel(id: $id, address: $address, body: $body, isMine: $isMine)';
  }
}
