import 'package:flutter/foundation.dart';

import '../models/offence.dart';
import '../models/offence_image.dart';
import 'database_service.dart';

/// The bridge between the database and the UI. Widgets watch this; when an
/// offence is added, it reloads and notifies, so lists refresh automatically.
class OffenceStore extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Offence> _offences = [];
  List<Offence> get offences => _offences;

  int get pendingCount =>
      _offences.where((o) => o.syncStatus == 'pending').length;

  Future<void> load() async {
    _offences = await _db.allOffences();
    notifyListeners();
  }

  /// Save an offence and any evidence photos together as one bundle.
  Future<void> add(Offence offence,
      {List<OffenceImage> images = const []}) async {
    await _db.insertOffence(offence);
    for (final image in images) {
      await _db.insertImage(image);
    }
    _offences = [offence, ..._offences];
    notifyListeners();
  }

  Future<List<OffenceImage>> imagesFor(String offenceId) =>
      _db.imagesForOffence(offenceId);
}
