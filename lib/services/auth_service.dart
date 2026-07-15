import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'database_service.dart';
import 'pin_service.dart';

/// Holds the authentication state for the whole app.
class AuthService extends ChangeNotifier {
  AuthService({required this.pin}) {
    // Global 401 handler: if the server ever says the token is invalid
    // (expired, revoked device, deactivated account), log out cleanly so the
    // officer lands on the login screen instead of seeing broken requests.
    _api.dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) async {
        final isLoginCall = e.requestOptions.path.endsWith('/login');
        if (e.response?.statusCode == 401 && !isLoginCall && isLoggedIn) {
          await logout();
        }
        handler.next(e);
      },
    ));
  }

  final PinService pin;
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';

  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  String? get error => _error;

  ApiClient get api => _api;

  /// Called once at app start. Only a genuine 401 (token revoked/expired)
  /// logs the user out — network failures keep the session so officers
  /// aren't bounced to the login screen when connectivity is poor.
  Future<void> tryAutoLogin() async {
    final saved = await _storage.read(key: _tokenKey);
    if (saved != null) {
      _token = saved;
      _api.setToken(saved);
      try {
        final res = await _api.dio.get('/me');
        _user = User.fromJson(res.data as Map<String, dynamic>);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await logout();
        }
        // Other failures (offline, timeout): keep the session.
      } catch (_) {
        // Non-Dio errors: keep the session.
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
    await DatabaseService.instance.clearWatchlist();
    await pin.clearPin(); // next user of this device sets their own PIN
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
