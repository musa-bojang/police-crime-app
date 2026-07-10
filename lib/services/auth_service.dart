import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'database_service.dart';

/// Holds the authentication state for the whole app.
///
/// It extends ChangeNotifier: whenever something changes (login, logout,
/// loading), it calls notifyListeners(), and any widget "watching" it rebuilds.
/// That's how the UI reacts without us manually refreshing screens.
class AuthService extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  String? get error => _error;

  /// Exposed so later services (sync, image upload) can reuse the same
  /// authenticated Dio instance.
  ApiClient get api => _api;

  /// Called once at app start: if a token was saved from a previous session,
  /// load it and verify it still works by calling /me.
  Future<void> tryAutoLogin() async {
    final saved = await _storage.read(key: _tokenKey);
    if (saved != null) {
      _token = saved;
      _api.setToken(saved);
      try {
        final res = await _api.dio.get('/me');
        _user = User.fromJson(res.data as Map<String, dynamic>);
      } catch (_) {
        await logout(); // token expired or invalid — clear it
      }
    }
    notifyListeners();
  }

  Future<bool> login(
      String serviceNumber, String password, String deviceName) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.post('/login', data: {
        'service_number': serviceNumber,
        'password': password,
        'device_name': deviceName,
      });

      final data = res.data as Map<String, dynamic>;
      _token = data['token'] as String;
      _user = User.fromJson(data['user'] as Map<String, dynamic>);

      _api.setToken(_token);
      await _storage.write(key: _tokenKey, value: _token);

      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _loading = false;
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/logout');
    } catch (_) {
      // Ignore network errors — we clear locally regardless.
    }
    _token = null;
    _user = null;
    _api.setToken(null);
    await _storage.delete(key: _tokenKey);
    await DatabaseService.instance.clearWatchlist(); // don't leave sensitive data on the device
    notifyListeners();
  }

  String _friendlyError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check the API address and that it is running.';
    }
    final code = e.response?.statusCode;
    if (code == 422) return 'Incorrect service number or password.';
    if (code == 429) return 'Too many attempts. Please wait a minute and try again.';
    return 'Something went wrong. Please try again.';
  }
}
