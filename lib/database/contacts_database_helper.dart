import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/model/contact_model.dart';
import '../utils/phone_utils.dart';

class ContactsDatabaseHelper {
  static final ContactsDatabaseHelper instance = ContactsDatabaseHelper._init();

  static Database? _database;

  ContactsDatabaseHelper._init();

  /* ---------------- DATABASE INIT ---------------- */

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            avatar BLOB
          )
        ''');

        /// Index for fast phone lookup
        await db.execute('''
          CREATE INDEX idx_contacts_phone ON contacts(phone)
        ''');
      },
    );
  }

  /* ---------------- INSERT / UPDATE ---------------- */

  Future<void> insertContact(ContactModel contact) async {
    final db = await database;
    await db.insert('contacts', contact.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertContacts(List<ContactModel> contacts) async {
    final db = await database;
    final batch = db.batch();

    for (final contact in contacts) {
      batch.insert('contacts', contact.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /* ---------------- GET CONTACT ---------------- */

  Future<ContactModel?> getContactByPhone(String phone) async {
    final db = await database;

    final normalized = PhoneUtils.normalize(phone, source: 'contact_db');

    final phoneDigits = normalized.replaceAll(RegExp(r'\D'), '');
    final last10 = phoneDigits.length > 10 ? phoneDigits.substring(phoneDigits.length - 10) : phoneDigits;

    final result = await db.query('contacts', where: 'phone LIKE ?', whereArgs: ['%$last10'], limit: 1);

    if (result.isNotEmpty) {
      return ContactModel.fromJson(result.first);
    }
    return null;
  }

  /* ---------------- GET ALL CONTACTS ---------------- */

  Future<List<ContactModel>> getAllContacts() async {
    final db = await database;
    final result = await db.query('contacts', orderBy: 'name ASC');

    return result.map(ContactModel.fromJson).toList();
  }

  /* ---------------- DELETE ---------------- */

  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearContacts() async {
    final db = await database;
    await db.delete('contacts');
  }

  /* ---------------- CLOSE ---------------- */

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
