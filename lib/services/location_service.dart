import 'package:geolocator/geolocator.dart';

/// Fetches the device's current GPS position, handling the service-enabled
/// check and the runtime permission prompt. Returns null (rather than throwing)
/// if location is unavailable or denied, so capture never gets blocked.
class LocationService {
  Future<Position?> getCurrentPosition() async {
    // Is location switched on at the OS level?
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    // Ask for permission if we don't already have it.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // Timed out or no fix available — carry on without coordinates.
      return null;
    }
  }
}
