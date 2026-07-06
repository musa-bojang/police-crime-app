import 'package:uuid/uuid.dart';

/// Represents one traffic offence — both in the local SQLite outbox and,
/// later, in the sync payload sent to the server.
///
/// Extra local-only fields (syncStatus, referenceNumber, serverStatus) let the
/// phone track what has and hasn't reached the backend yet.
class Offence {
  final String id; // client-generated UUID (offline-first key)
  final String offenceType;
  final String? offenceDescription;
  final String? vehiclePlate;
  final String? vehicleColor;
  final String? vehicleMake;
  final String? vehicleType;
  final String? driverGender;
  final String? driverName;
  final bool driverFled;
  final double? latitude;
  final double? longitude;
  final String? locationDescription;
  final DateTime occurredAt;
  final DateTime capturedAt;

  // Local sync tracking
  final String syncStatus; // pending | synced | failed
  final String? referenceNumber; // filled in from the server after sync
  final String? serverStatus; // submitted | confirmed | dismissed (from server)
  final DateTime createdAt;

  Offence({
    required this.id,
    required this.offenceType,
    this.offenceDescription,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleMake,
    this.vehicleType,
    this.driverGender,
    this.driverName,
    this.driverFled = false,
    this.latitude,
    this.longitude,
    this.locationDescription,
    required this.occurredAt,
    required this.capturedAt,
    this.syncStatus = 'pending',
    this.referenceNumber,
    this.serverStatus,
    required this.createdAt,
  });

  /// Build a brand-new offence being captured now. Generates the UUID and
  /// timestamps so the caller only supplies the field data.
  factory Offence.create({
    required String offenceType,
    String? offenceDescription,
    String? vehiclePlate,
    String? vehicleColor,
    String? vehicleMake,
    String? vehicleType,
    String? driverGender,
    String? driverName,
    bool driverFled = false,
    double? latitude,
    double? longitude,
    String? locationDescription,
  }) {
    final now = DateTime.now();
    return Offence(
      id: const Uuid().v4(),
      offenceType: offenceType,
      offenceDescription: offenceDescription,
      vehiclePlate: vehiclePlate,
      vehicleColor: vehicleColor,
      vehicleMake: vehicleMake,
      vehicleType: vehicleType,
      driverGender: driverGender,
      driverName: driverName,
      driverFled: driverFled,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      occurredAt: now,
      capturedAt: now,
      createdAt: now,
    );
  }

  /// Convert to a row for SQLite. SQLite has no boolean or date types, so we
  /// store bools as 0/1 and dates as ISO-8601 text.
  Map<String, dynamic> toMap() => {
        'id': id,
        'offence_type': offenceType,
        'offence_description': offenceDescription,
        'vehicle_plate': vehiclePlate,
        'vehicle_color': vehicleColor,
        'vehicle_make': vehicleMake,
        'vehicle_type': vehicleType,
        'driver_gender': driverGender,
        'driver_name': driverName,
        'driver_fled': driverFled ? 1 : 0,
        'latitude': latitude,
        'longitude': longitude,
        'location_description': locationDescription,
        'occurred_at': occurredAt.toIso8601String(),
        'captured_at': capturedAt.toIso8601String(),
        'sync_status': syncStatus,
        'reference_number': referenceNumber,
        'server_status': serverStatus,
        'created_at': createdAt.toIso8601String(),
      };

  /// Rebuild an Offence from a SQLite row.
  factory Offence.fromMap(Map<String, dynamic> m) => Offence(
        id: m['id'] as String,
        offenceType: m['offence_type'] as String,
        offenceDescription: m['offence_description'] as String?,
        vehiclePlate: m['vehicle_plate'] as String?,
        vehicleColor: m['vehicle_color'] as String?,
        vehicleMake: m['vehicle_make'] as String?,
        vehicleType: m['vehicle_type'] as String?,
        driverGender: m['driver_gender'] as String?,
        driverName: m['driver_name'] as String?,
        driverFled: (m['driver_fled'] as int? ?? 0) == 1,
        latitude: m['latitude'] as double?,
        longitude: m['longitude'] as double?,
        locationDescription: m['location_description'] as String?,
        occurredAt: DateTime.parse(m['occurred_at'] as String),
        capturedAt: DateTime.parse(m['captured_at'] as String),
        syncStatus: m['sync_status'] as String? ?? 'pending',
        referenceNumber: m['reference_number'] as String?,
        serverStatus: m['server_status'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
