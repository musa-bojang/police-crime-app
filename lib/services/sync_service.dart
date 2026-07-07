import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/offence.dart';
import '../models/offence_image.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'offence_store.dart';

/// The sync engine. Pushes pending offences to the API, uploads their photos
/// (which the server re-hashes and verifies), then removes fully-synced records
/// from the local outbox. Runs on demand and automatically when the connection
/// returns.
class SyncService extends ChangeNotifier {
  SyncService({required this.auth, required this.store}) {
    // Auto-sync whenever connectivity comes back.
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) syncNow();
    });
  }

  final AuthService auth;
  final OffenceStore store;
  final DatabaseService _db = DatabaseService.instance;
  late final StreamSubscription _sub;

  bool _syncing = false;
  bool get syncing => _syncing;

  String? _message;
  String? get message => _message;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<bool> _isOnline() async {
    final r = await Connectivity().checkConnectivity();
    return r.any((e) => e != ConnectivityResult.none);
  }

  Future<void> syncNow() async {
    // Guard: don't run twice at once, when logged out, or when offline.
    if (_syncing || !auth.isLoggedIn) return;
    if (!await _isOnline()) return;

    _syncing = true;
    _message = null;
    notifyListeners();

    try {
      await _pushOffences();
      await _uploadImages();
      await _cleanupSynced();
      await store.load(); // refresh the outbox list
      _message = 'Sync complete';
    } on DioException catch (e) {
      _message = 'Sync failed: ${e.message ?? 'network error'}';
    } catch (_) {
      _message = 'Sync failed';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Step 1: push all pending offences in one idempotent batch.
  Future<void> _pushOffences() async {
    final pending = await _db.pendingOffences();
    if (pending.isEmpty) return;

    final payload = <Map<String, dynamic>>[];
    for (final o in pending) {
      final imgs = await _db.pendingImagesForOffence(o.id);
      payload.add(_offencePayload(o, imgs));
    }

    final res =
        await auth.api.dio.post('/sync/offences', data: {'offences': payload});
    final results = (res.data['results'] as List).cast<Map<String, dynamic>>();

    for (final r in results) {
      final id = r['id'] as String;
      final status = r['status'] as String;
      if (status == 'accepted' || status == 'conflict') {
        await _db.updateOffenceSync(
          id,
          syncStatus: 'synced',
          referenceNumber: r['reference_number'] as String?,
          serverStatus: r['server_status'] as String?,
        );
      } else {
        await _db.updateOffenceSync(id, syncStatus: 'failed');
      }
    }
  }

  /// Step 2: upload the photo files for offences already on the server. The
  /// server re-hashes each one and verifies it against the hash we sent.
  Future<void> _uploadImages() async {
    final offences = await _db.allOffences();
    for (final o in offences) {
      if (o.syncStatus != 'synced') continue;

      final imgs = await _db.pendingImagesForOffence(o.id);
      for (final img in imgs) {
        try {
          final form = FormData.fromMap({
            'file': await MultipartFile.fromFile(img.filePath,
                filename: '${img.id}.jpg'),
          });
          await auth.api.dio.post('/sync/images/${img.id}/file', data: form);
          await _db.markImage(img.id, 'synced');
        } on DioException {
          // Includes a 422 hash-mismatch (server quarantined it) — mark failed.
          await _db.markImage(img.id, 'failed');
        }
      }
    }
  }

  /// Step 3: a fully-synced offence (record + all photos on the server) leaves
  /// the phone. We delete the local photo files too — less sensitive data
  /// lingering on the device.
  Future<void> _cleanupSynced() async {
    final offences = await _db.allOffences();
    for (final o in offences) {
      if (o.syncStatus != 'synced') continue;

      final imgs = await _db.imagesForOffence(o.id);
      final allDone = imgs.every((i) => i.syncStatus == 'synced');
      if (!allDone) continue;

      for (final i in imgs) {
        try {
          await File(i.filePath).delete();
        } catch (_) {
          // Already gone — ignore.
        }
      }
      await _db.deleteOffence(o.id);
    }
  }

  Map<String, dynamic> _offencePayload(Offence o, List<OffenceImage> imgs) => {
        'id': o.id,
        'offence_type': o.offenceType,
        'offence_description': o.offenceDescription,
        'vehicle_plate': o.vehiclePlate,
        'vehicle_color': o.vehicleColor,
        'vehicle_make': o.vehicleMake,
        'vehicle_type': o.vehicleType,
        'driver_gender': o.driverGender,
        'driver_name': o.driverName,
        'driver_fled': o.driverFled,
        'latitude': o.latitude,
        'longitude': o.longitude,
        'location_description': o.locationDescription,
        'occurred_at': o.occurredAt.toIso8601String(),
        'captured_at': o.capturedAt.toIso8601String(),
        'images': imgs
            .map((i) => {
                  'id': i.id,
                  'sha256_hash': i.sha256Hash,
                  'mime_type': i.mimeType,
                  'file_size': i.fileSize,
                  'latitude': i.latitude,
                  'longitude': i.longitude,
                  'captured_at': i.capturedAt.toIso8601String(),
                })
            .toList(),
      };
}
