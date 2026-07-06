import 'package:dio/dio.dart';

// The address of your Laravel API.
//
// Android EMULATOR: the host PC's localhost is reachable at 10.0.2.2,
// so this default works with `php artisan serve` as-is.
//
// PHYSICAL PHONE: change this to your PC's LAN IP (e.g. http://192.168.1.20:8000/api)
// and start the server with `php artisan serve --host=0.0.0.0` so the phone can reach it.
const String kBaseUrl = 'http://10.0.2.2:8000/api';

/// Thin wrapper around Dio. One instance is shared across the app so that once
/// we set the auth token, every request carries it automatically.
class ApiClient {
  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
  }

  late final Dio dio;

  /// Attach or clear the bearer token used by the Sanctum-protected routes.
  void setToken(String? token) {
    if (token == null) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
