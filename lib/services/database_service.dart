import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/offence.dart';
import '../models/offence_image.dart';
import '../models/watchlist_vehicle.dart';

/// Owns the on-device SQLite database. Holds the outbox (offences + photos) and
/// a cached copy of the active watchlist for offline plate checks.
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
      version: 4, // v4 adds the sightings outbox
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createOffences(db);
    await _createImages(db);
    await _createWatchlist(db);
    await _createSightings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createImages(db);
    if (oldVersion < 3) await _createWatchlist(db);
    if (oldVersion < 4) await _createSightings(db);
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

  Future<void> _createWatchlist(Database db) async {
    await db.execute('''
      CREATE TABLE watchlist_vehicles (
        id INTEGER PRIMARY KEY,
        plate TEXT NOT NULL,
        plate_normalized TEXT NOT NULL,
        vehicle_make TEXT,
        vehicle_color TEXT,
        vehicle_type TEXT,
        reason TEXT NOT NULL,
        severity TEXT NOT NULL,
        instructions TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_watchlist_plate ON watchlist_vehicles(plate_normalized)');
  }

  /// Outbox for sightings recorded while offline — pushed on next sync.
  Future<void> _createSightings(Database db) async {
    await db.execute('''
      CREATE TABLE pending_sightings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        watchlist_vehicle_id INTEGER NOT NULL,
        plate_checked TEXT,
        latitude REAL,
        longitude REAL,
        sighted_at TEXT NOT NULL
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

  /// Images that still need uploading — pending AND failed, so a failed
  /// upload is retried on the next sync instead of being stranded.
  Future<List<OffenceImage>> pendingImagesForOffence(String offenceId) async {
    final db = await _database;
    final rows = await db.query('offence_images',
        where: "offence_id = ? AND sync_status IN ('pending','failed')",
        whereArgs: [offenceId]);
    return rows.map(OffenceImage.fromMap).toList();
  }

  Future<void> markImage(String id, String syncStatus) async {
    final db = await _database;
    await db.update('offence_images', {'sync_status': syncStatus},
        where: 'id = ?', whereArgs: [id]);
  }

  // --- Watchlist cache ---

  /// Replace the entire cached watchlist with a fresh copy from the server.
  Future<void> replaceWatchlist(List<WatchlistVehicle> vehicles) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('watchlist_vehicles');
      for (final v in vehicles) {
        await txn.insert('watchlist_vehicles', v.toMap());
      }
    });
  }

  /// Find any wanted vehicles whose normalised plate exactly matches.
  Future<List<WatchlistVehicle>> searchWatchlist(String normalizedPlate) async {
    final db = await _database;
    final rows = await db.query('watchlist_vehicles',
        where: 'plate_normalized = ?', whereArgs: [normalizedPlate]);
    return rows.map(WatchlistVehicle.fromMap).toList();
  }

  Future<int> watchlistCount() async {
    final db = await _database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM watchlist_vehicles');
    return (result.first['c'] as int?) ?? 0;
  }

  /// Wipe the cached watchlist — called on logout so sensitive data doesn't
  /// linger on the device.
  Future<void> clearWatchlist() async {
    final db = await _database;
    await db.delete('watchlist_vehicles');
  }

  // --- Sightings outbox ---

  Future<void> queueSighting({
    required int watchlistVehicleId,
    String? plateChecked,
    double? latitude,
    double? longitude,
  }) async {
    final db = await _database;
    await db.insert('pending_sightings', {
      'watchlist_vehicle_id': watchlistVehicleId,
      'plate_checked': plateChecked,
      'latitude': latitude,
      'longitude': longitude,
      'sighted_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> pendingSightings() async {
    final db = await _database;
    return db.query('pending_sightings', orderBy: 'sighted_at ASC');
  }

  Future<void> deletePendingSighting(int id) async {
    final db = await _database;
    await db.delete('pending_sightings', where: 'id = ?', whereArgs: [id]);
  }
}
