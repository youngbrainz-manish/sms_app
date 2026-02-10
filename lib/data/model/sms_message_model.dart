import 'dart:typed_data';
import 'dart:convert';

class SmsMessageModel {
  final int? id;
  final Uint8List? avatar;
  final String? name;
  final String? address;
  final String? body;
  final int? date;
  final bool? isMine;
  final bool? isRead;
  final String? category;
  final int? unreadCount;

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
    this.unreadCount = 0,
  });

  // CopyWith method
  SmsMessageModel copyWith({
    int? id,
    Uint8List? avatar,
    String? name,
    String? address,
    String? body,
    int? date,
    bool? isMine,
    bool? isRead,
    String? category,
    int? unreadCount,
  }) {
    return SmsMessageModel(
      id: id ?? this.id,
      avatar: avatar ?? this.avatar,
      name: name ?? this.name,
      address: address ?? this.address,
      body: body ?? this.body,
      date: date ?? this.date,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  // From JSON
  factory SmsMessageModel.fromJson(Map<String, dynamic> json) {
    return SmsMessageModel(
      id: json['id'] as int?,
      avatar: json['photo_uri'] != null ? json['photo_uri'] as Uint8List? : null,
      name: json['contact_name'] as String?,
      address: json['address'] as String?,
      body: json['body'] as String?,
      date: json['date'] as int?,
      isMine: json['is_mine'].toString() == "1",
      isRead: json['is_read'].toString() == "1",
      category: json['category'] as String?,
      unreadCount: (json['unread_count'] ?? 0) as int,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photo_uri': avatar != null ? base64Encode(avatar!) : null,
      'contact_name': name,
      'address': address,
      'body': body,
      'date': date,
      'isMine': isMine,
      'isRead': isRead,
      'category': category,
      'unreadCount': unreadCount,
    };
  }
}
