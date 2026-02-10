import 'package:new_sms_app/database/contacts_database_helper.dart';
import 'package:new_sms_app/utils/phone_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// 🔥 Broadcast controller to notify conversation updates
  final StreamController<String> _conversationUpdateController = StreamController<String>.broadcast();

  Stream<String> get conversationUpdates => _conversationUpdateController.stream;

  /* ---------------- DATABASE INIT ---------------- */

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sms_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            address TEXT,
            body TEXT,
            date INTEGER,
            is_mine INTEGER,
            is_read INTEGER DEFAULT 0,
            contact_name TEXT,
            photo_uri TEXT,
            category TEXT,
            UNIQUE(address, date)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            DELETE FROM messages
            WHERE id NOT IN (
              SELECT MAX(id)
              FROM messages
              GROUP BY address, date
            )
          ''');

          await db.execute('''
            CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_sms
            ON messages(address, date)
          ''');
        }
      },
    );
  }

  /* ---------------- INSERT MESSAGE ---------------- */

  Future<void> insertMessage(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.ignore);

    final address = row['address'];
    if (address != null) {
      _conversationUpdateController.add(address);
    }
  }

  /* ---------------- INBOX QUERY ---------------- */
  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;

    final messages = await db.rawQuery('''
    SELECT 
      m.*,
      (
        SELECT COUNT(*)
        FROM messages
        WHERE address = m.address
        AND is_read = 0
        AND is_mine = 0
      ) AS unread_count
    FROM messages m
    INNER JOIN (
      SELECT address, MAX(date) AS max_date
      FROM messages
      GROUP BY address
    ) grouped
    ON m.address = grouped.address 
    AND m.date = grouped.max_date
    ORDER BY m.date DESC
  ''');

    return messages;
  }

  /* ---------------- CONVERSATION QUERY ---------------- */

  Future<List<Map<String, dynamic>>> getInboxWithContacts() async {
    final rawMessages = await getMessages();
    final contactsDb = ContactsDatabaseHelper.instance;

    final List<Map<String, dynamic>> enrichedMessages = [];

    for (final row in rawMessages) {
      // 🔥 MAKE MUTABLE COPY
      final msg = Map<String, dynamic>.from(row);

      final address = msg['address'] as String?;

      // 🔴 VERY IMPORTANT
      if (!isNumericSender(address)) {
        msg['contact_name'] = address; // show sender ID
        msg['photo_uri'] = null;
        continue;
      }
      if (address != null) {
        final contact = await contactsDb.getContactByPhone(address);

        if (contact != null) {
          msg['contact_name'] = contact.name;
          msg['photo_uri'] = contact.avatar;
        }
      }

      enrichedMessages.add(msg);
    }

    return enrichedMessages;
  }

  /* ---------------- CONVERSATION QUERY ---------------- */

  Future<List<Map<String, dynamic>>> getConversation(String address) async {
    final db = await database;
    final addresss = PhoneUtils.normalize(address, source: '1');
    return await db.query('messages', where: 'address = ?', whereArgs: [addresss], orderBy: 'date ASC');
  }

  /* ---------------- MARK AS READ ---------------- */

  Future<void> markAsRead(String address) async {
    final db = await database;
    final addresss = PhoneUtils.normalize(address, source: '2');

    await db.update('messages', {'is_read': 1}, where: 'address = ? AND is_read = 0', whereArgs: [addresss]);

    _conversationUpdateController.add(address);
  }

  /* ---------------- REAL STREAM (NO POLLING) ---------------- */

  Stream<List<Map<String, dynamic>>> conversationStream(String address) async* {
    // Initial load
    yield await getConversation(address);
    await for (final updatedAddress in conversationUpdates) {
      if (updatedAddress == address) {
        yield await getConversation(address);
      }
    }
  }

  /* ---------------- Normalize Old Numbers ---------------- */

  Future<void> normalizeOldNumbers() async {
    final db = await database;

    final rows = await db.query('messages', orderBy: 'date ASC');

    for (final row in rows) {
      final int id = row['id'] as int;
      final String oldAddress = row['address'] as String;
      final String normalized = PhoneUtils.normalize(oldAddress, source: '3');

      if (normalized == oldAddress) continue;

      try {
        await db.update('messages', {'address': normalized}, where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        // 🔥 DUPLICATE FOUND — DELETE OLD ROW
        await db.delete('messages', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  /* ---------------- CLEANUP ---------------- */

  void dispose() {
    _conversationUpdateController.close();
  }

  static bool isNumericSender(String? address) {
    if (address == null) return false;
    return RegExp(r'\d').hasMatch(address);
  }
}
