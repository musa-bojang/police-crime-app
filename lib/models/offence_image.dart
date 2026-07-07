/// Device-side record of an evidence photo waiting in the outbox. Mirrors the
/// fields the server's offence_images table expects, plus a local sync status.
class OffenceImage {
  final String id; // client-generated UUID (matches the saved file name)
  final String offenceId;
  final String filePath; // absolute path on the device
  final String sha256Hash; // computed on-device at capture
  final String mimeType;
  final int fileSize;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final String syncStatus; // pending | synced | failed
  final DateTime createdAt;

  OffenceImage({
    required this.id,
    required this.offenceId,
    required this.filePath,
    required this.sha256Hash,
    this.mimeType = 'image/jpeg',
    required this.fileSize,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    this.syncStatus = 'pending',
    required this.createdAt,
  });

  factory OffenceImage.fromCapture({
    required String id,
    required String offenceId,
    required String filePath,
    required String sha256Hash,
    required int fileSize,
    String mimeType = 'image/jpeg',
    double? latitude,
    double? longitude,
  }) {
    final now = DateTime.now();
    return OffenceImage(
      id: id,
      offenceId: offenceId,
      filePath: filePath,
      sha256Hash: sha256Hash,
      fileSize: fileSize,
      mimeType: mimeType,
      latitude: latitude,
      longitude: longitude,
      capturedAt: now,
      createdAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'offence_id': offenceId,
        'file_path': filePath,
        'sha256_hash': sha256Hash,
        'mime_type': mimeType,
        'file_size': fileSize,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': capturedAt.toIso8601String(),
        'sync_status': syncStatus,
        'created_at': createdAt.toIso8601String(),
      };

  factory OffenceImage.fromMap(Map<String, dynamic> m) => OffenceImage(
        id: m['id'] as String,
        offenceId: m['offence_id'] as String,
        filePath: m['file_path'] as String,
        sha256Hash: m['sha256_hash'] as String,
        mimeType: m['mime_type'] as String? ?? 'image/jpeg',
        fileSize: m['file_size'] as int? ?? 0,
        latitude: m['latitude'] as double?,
        longitude: m['longitude'] as double?,
        capturedAt: DateTime.parse(m['captured_at'] as String),
        syncStatus: m['sync_status'] as String? ?? 'pending',
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
