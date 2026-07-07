import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// The result of taking one photo: a permanently-saved file plus the fingerprint
/// the server will verify.
class CapturedPhoto {
  final String id;
  final String filePath;
  final String sha256Hash;
  final int fileSize;
  final String mimeType;

  CapturedPhoto({
    required this.id,
    required this.filePath,
    required this.sha256Hash,
    required this.fileSize,
    this.mimeType = 'image/jpeg',
  });
}

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Launches the camera, saves the photo to the app's private evidence folder,
  /// and hashes it. Returns null if the officer cancels.
  Future<CapturedPhoto?> takePhoto() async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // compress on-device
      maxWidth: 1920, // enough to read a plate, small enough to upload
    );
    if (shot == null) return null;

    final bytes = await shot.readAsBytes();

    // Private, app-only storage — never the shared gallery.
    final dir = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory(p.join(dir.path, 'evidence'));
    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }

    final id = const Uuid().v4();
    final path = p.join(evidenceDir.path, '$id.jpg');
    await File(path).writeAsBytes(bytes);

    // Hash the exact bytes we saved — this must match what we later upload,
    // because the server re-computes SHA-256 and compares.
    final hash = sha256.convert(bytes).toString();

    return CapturedPhoto(
      id: id,
      filePath: path,
      sha256Hash: hash,
      fileSize: bytes.length,
    );
  }
}
