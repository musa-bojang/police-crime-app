import 'package:flutter/foundation.dart';

import '../models/offence.dart';
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

  Future<void> add(Offence offence) async {
    await _db.insertOffence(offence);
    _offences = [offence, ..._offences];
    notifyListeners();
  }
}
