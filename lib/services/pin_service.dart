import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App PIN lock. The PIN is never stored — only a salted SHA-256 hash in the
/// device's secure storage. The app locks when it has been in the background
/// longer than [timeout], and on every cold start when a PIN exists.
class PinService extends ChangeNotifier {
  static const timeout = Duration(minutes: 10);

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool _hasPin = false;
  bool _locked = false;
  DateTime? _backgroundedAt;

  bool get hasPin => _hasPin;
  bool get locked => _locked;

  /// Call once at startup. If a PIN exists, the app starts locked.
  Future<void> init() async {
    _hasPin = (await _storage.read(key: _hashKey)) != null;
    _locked = _hasPin; // cold start with a PIN = locked
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: _hash(pin, salt));
    _hasPin = true;
    _locked = false;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final stored = await _storage.read(key: _hashKey);
    if (salt == null || stored == null) return false;

    final ok = _hash(pin, salt) == stored;
    if (ok) {
      _locked = false;
      notifyListeners();
    }
    return ok;
  }

  /// Remove the PIN entirely — called on logout so the next user of the
  /// device sets their own.
  Future<void> clearPin() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
    _hasPin = false;
    _locked = false;
    notifyListeners();
  }

  // --- Lifecycle hooks (called from the app's lifecycle observer) ---

  void appBackgrounded() {
    _backgroundedAt = DateTime.now();
  }

  void appResumed() {
    if (!_hasPin || _locked) return;
    final away = _backgroundedAt;
    if (away != null && DateTime.now().difference(away) >= timeout) {
      _locked = true;
      notifyListeners();
    }
  }

  String _randomSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
