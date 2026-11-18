import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models.dart';

/// Local SQLite storage. All data stays on the device; there is no cloud.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  Future<Database> get database async {
    final db = _db;
    if (db != null) return db;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'vitalkin.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE members(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            relation TEXT NOT NULL,
            height_cm REAL
          )''');
        await db.execute('''
          CREATE TABLE readings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            value1 REAL NOT NULL,
            value2 REAL,
            sugar_type TEXT,
            note TEXT,
            timestamp INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE medicines(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            member_id INTEGER NOT NULL REFERENCES members(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            dose TEXT NOT NULL,
            times TEXT NOT NULL,
            note TEXT
          )''');
        await db.execute(
            'CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
  }

  // --- meta (onboarding flag) ---
  Future<bool> isOnboardingDone() async {
    final db = await database;
    final rows = await db.query('meta',
        where: 'key = ?', whereArgs: ['onboarding_done']);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> setOnboardingDone() async {
    final db = await database;
    await db.insert('meta', {'key': 'onboarding_done', 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- members ---
  Future<int> insertMember(Member member) async {
    final db = await database;
    return db.insert('members', member.toMap());
  }

  Future<List<Member>> getMembers() async {
    final db = await database;
    final rows = await db.query('members', orderBy: 'name ASC');
    return rows.map(Member.fromMap).toList();
  }

  Future<Member?> getMember(int id) async {
    final db = await database;
    final rows = await db.query('members', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Member.fromMap(rows.first);
  }

  Future<void> updateMember(Member member) async {
    final db = await database;
    await db.update('members', member.toMap(),
        where: 'id = ?', whereArgs: [member.id]);
  }

  Future<void> deleteMember(int id) async {
    final db = await database;
    await db.delete('readings', where: 'member_id = ?', whereArgs: [id]);
    await db.delete('medicines', where: 'member_id = ?', whereArgs: [id]);
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // --- readings ---
  Future<int> insertReading(Reading reading) async {
    final db = await database;
    return db.insert('readings', reading.toMap());
  }

  Future<List<Reading>> getReadings(int memberId, {String? type}) async {
    final db = await database;
    final rows = await db.query(
      'readings',
      where: type == null ? 'member_id = ?' : 'member_id = ? AND type = ?',
      whereArgs: type == null ? [memberId] : [memberId, type],
      orderBy: 'timestamp DESC',
    );
    return rows.map(Reading.fromMap).toList();
  }

  Future<Reading?> latestReading(int memberId, String type) async {
    final readings = await getReadings(memberId, type: type);
    return readings.isEmpty ? null : readings.first;
  }

  Future<void> deleteReading(int id) async {
    final db = await database;
    await db.delete('readings', where: 'id = ?', whereArgs: [id]);
  }

  // --- medicines ---
  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return db.insert('medicines', medicine.toMap());
  }

  Future<List<Medicine>> getMedicines(int memberId) async {
    final db = await database;
    final rows = await db.query('medicines',
        where: 'member_id = ?', whereArgs: [memberId], orderBy: 'name ASC');
    return rows.map(Medicine.fromMap).toList();
  }

  Future<void> deleteMedicine(int id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }
}
