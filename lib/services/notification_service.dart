import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/watchlist_vehicle.dart';

/// Shows local (on-device) notifications for new watchlist alerts.
/// Polling model: alerts fire when a sync discovers new entries — later this
/// same service can be driven by FCM pushes without changing its callers.
///
/// NOTE: written for flutter_local_notifications ^19.x (classic API). The
/// package is pinned to that major version in pubspec.yaml; v20+ redesigned
/// the method signatures.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );

    // Android 13+ requires asking for the notification permission at runtime.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _ready = true;
  }

  Future<void> showWatchlistAlert(WatchlistVehicle v) async {
    await init();

    final severity = v.severity.toUpperCase();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'watchlist_alerts',                   // channel id
        'Watchlist alerts',                   // channel name (visible in settings)
        channelDescription:
            'New wanted-vehicle alerts issued by supervisors',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFD32F2F),
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      v.id,                                    // one notification per entry
      '$severity — vehicle ${v.plate}',
      v.reason,
      details,
    );
  }
}
