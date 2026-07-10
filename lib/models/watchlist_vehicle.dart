/// Device-side copy of a wanted vehicle, cached locally so plate checks work
/// offline. Mirrors the fields the API's /watchlist endpoint returns.
class WatchlistVehicle {
  final int id; // server id — used when reporting a sighting
  final String plate;
  final String plateNormalized;
  final String? vehicleMake;
  final String? vehicleColor;
  final String? vehicleType;
  final String reason;
  final String severity; // caution | wanted | dangerous
  final String? instructions;

  WatchlistVehicle({
    required this.id,
    required this.plate,
    required this.plateNormalized,
    this.vehicleMake,
    this.vehicleColor,
    this.vehicleType,
    required this.reason,
    required this.severity,
    this.instructions,
  });

  /// Normalise a plate the same way the server does: uppercase, letters and
  /// digits only. Used to match what the officer types against the cache.
  static String normalizePlate(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  factory WatchlistVehicle.fromJson(Map<String, dynamic> json) =>
      WatchlistVehicle(
        id: json['id'] as int,
        plate: json['plate'] as String,
        plateNormalized: json['plate_normalized'] as String,
        vehicleMake: json['vehicle_make'] as String?,
        vehicleColor: json['vehicle_color'] as String?,
        vehicleType: json['vehicle_type'] as String?,
        reason: json['reason'] as String,
        severity: json['severity'] as String,
        instructions: json['instructions'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'plate': plate,
        'plate_normalized': plateNormalized,
        'vehicle_make': vehicleMake,
        'vehicle_color': vehicleColor,
        'vehicle_type': vehicleType,
        'reason': reason,
        'severity': severity,
        'instructions': instructions,
      };

  factory WatchlistVehicle.fromMap(Map<String, dynamic> m) => WatchlistVehicle(
        id: m['id'] as int,
        plate: m['plate'] as String,
        plateNormalized: m['plate_normalized'] as String,
        vehicleMake: m['vehicle_make'] as String?,
        vehicleColor: m['vehicle_color'] as String?,
        vehicleType: m['vehicle_type'] as String?,
        reason: m['reason'] as String,
        severity: m['severity'] as String,
        instructions: m['instructions'] as String?,
      );
}
