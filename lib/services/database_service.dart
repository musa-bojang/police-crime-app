import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/offence.dart';

/// Owns the on-device SQLite database — the offline "outbox". Offences are
/// written here first, always, and later read back for syncing.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'police_app.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offences (
        id TEXT PRIMARY KEY,
        offence_type TEXT NOT NULL,
        offence_description TEXT,
        vehicle_plate TEXT,
        vehicle_color TEXT,
        vehicle_make TEXT,
        vehicle_type TEXT,
        driver_gender TEXT,
        driver_name TEXT,
        driver_fled INTEGER NOT NULL DEFAULT 0,
        latitude REAL,
        longitude REAL,
        location_description TEXT,
        occurred_at TEXT NOT NULL,
        captured_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        reference_number TEXT,
        server_status TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertOffence(Offence offence) async {
    final db = await _database;
    await db.insert(
      'offences',
      offence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Offence>> allOffences() async {
    final db = await _database;
    final rows = await db.query('offences', orderBy: 'created_at DESC');
    return rows.map(Offence.fromMap).toList();
  }
}
