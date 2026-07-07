import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/offence.dart';
import '../models/offence_image.dart';

/// Owns the on-device SQLite database — the offline "outbox". Offences and their
/// evidence photos are written here first, always, then read back for syncing.
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
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createOffences(db);
    await _createImages(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createImages(db);
    }
  }

  Future<void> _createOffences(Database db) async {
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

  Future<void> _createImages(Database db) async {
    await db.execute('''
      CREATE TABLE offence_images (
        id TEXT PRIMARY KEY,
        offence_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        sha256_hash TEXT NOT NULL,
        mime_type TEXT,
        file_size INTEGER,
        latitude REAL,
        longitude REAL,
        captured_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // --- Offences ---

  Future<void> insertOffence(Offence offence) async {
    final db = await _database;
    await db.insert('offences', offence.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Offence>> allOffences() async {
    final db = await _database;
    final rows = await db.query('offences', orderBy: 'created_at DESC');
    return rows.map(Offence.fromMap).toList();
  }

  /// Offences that still need to reach the server (never synced, or failed).
  Future<List<Offence>> pendingOffences() async {
    final db = await _database;
    final rows = await db.query('offences',
        where: "sync_status IN ('pending','failed')",
        orderBy: 'created_at ASC');
    return rows.map(Offence.fromMap).toList();
  }

  Future<void> updateOffenceSync(
    String id, {
    required String syncStatus,
    String? referenceNumber,
    String? serverStatus,
  }) async {
    final db = await _database;
    final data = <String, dynamic>{'sync_status': syncStatus};
    if (referenceNumber != null) data['reference_number'] = referenceNumber;
    if (serverStatus != null) data['server_status'] = serverStatus;
    await db.update('offences', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOffence(String id) async {
    final db = await _database;
    await db.delete('offence_images', where: 'offence_id = ?', whereArgs: [id]);
    await db.delete('offences', where: 'id = ?', whereArgs: [id]);
  }

  // --- Images ---

  Future<void> insertImage(OffenceImage image) async {
    final db = await _database;
    await db.insert('offence_images', image.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OffenceImage>> imagesForOffence(String offenceId) async {
    final db = await _database;
    final rows = await db.query('offence_images',
        where: 'offence_id = ?', whereArgs: [offenceId]);
    return rows.map(OffenceImage.fromMap).toList();
  }

  Future<List<OffenceImage>> pendingImagesForOffence(String offenceId) async {
    final db = await _database;
    final rows = await db.query('offence_images',
        where: "offence_id = ? AND sync_status = 'pending'",
        whereArgs: [offenceId]);
    return rows.map(OffenceImage.fromMap).toList();
  }

  Future<void> markImage(String id, String syncStatus) async {
    final db = await _database;
    await db.update('offence_images', {'sync_status': syncStatus},
        where: 'id = ?', whereArgs: [id]);
  }
}
