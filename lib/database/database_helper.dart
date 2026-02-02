import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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

  Future<void> insertMessage(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Future<List<Map<String, dynamic>>> getMessages() async {
  //   final db = await instance.database;
  //   return await db.rawQuery('''
  //   SELECT *
  //   FROM messages m
  //   INNER JOIN (
  //     SELECT address, MAX(date) as max_date
  //     FROM messages
  //     GROUP BY address
  //   ) grouped
  //   ON m.address = grouped.address AND m.date = grouped.max_date
  //   ORDER BY m.date DESC
  // ''');
  // }
  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await instance.database;

    return await db.rawQuery('''
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
  }

  Future<List<Map<String, dynamic>>> getConversation(String address) async {
    final db = await instance.database;
    return await db.query('messages', where: 'address = ?', whereArgs: [address], orderBy: 'date ASC');
  }

  Future<void> markAsRead(String address) async {
    final db = await instance.database;

    await db.update('messages', {'is_read': 1}, where: 'address = ? AND is_read = 0', whereArgs: [address]);
  }
}
