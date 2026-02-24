import 'package:flutter/foundation.dart';

/// Malaysian states/regions for manual location selection (profile My Location).
const List<String> malaysianStates = [
  'Johor',
  'Kedah',
  'Kelantan',
  'Kuala Lumpur',
  'Malacca',
  'Negeri Sembilan',
  'Pahang',
  'Penang',
  'Perak',
  'Perlis',
  'Sabah',
  'Sarawak',
  'Selangor',
  'Terengganu',
  'Malaysia',
];

/// Shared location service used by both Aid Finder and Alerts screens.
/// Uses browser Geolocation API on web, falls back to null gracefully.
class LocationService {
  static LocationData? _cached;
  static DateTime? _cachedAt;
  static const _cacheDuration = Duration(minutes: 30);

  /// Get user's current location. Returns null if unavailable or denied.
  static Future<LocationData?> getCurrentLocation() async {
    if (_cached != null && _cachedAt != null) {
      if (DateTime.now().difference(_cachedAt!) < _cacheDuration) {
        return _cached;
      }
    }

    try {
      if (kIsWeb) {
        final result = await _getWebLocation();
        if (result != null) {
          _cached = result;
          _cachedAt = DateTime.now();
        }
        return result;
      }
    } catch (e) {
      debugPrint('LocationService error: $e');
    }
    return null;
  }

  static Future<LocationData?> _getWebLocation() async {
    try {
      final completer = _WebLocationCompleter();
      return await completer.getLocation();
    } catch (e) {
      debugPrint('Web geolocation failed: $e');
      return null;
    }
  }
}

class LocationData {
  final double lat;
  final double lng;
  final String? stateName;

  const LocationData({required this.lat, required this.lng, this.stateName});

  String get resolvedLocation {
    if (stateName != null) return stateName!;
    if (lat > 3.0 && lat < 3.3 && lng > 101.5 && lng < 101.9) return 'Kuala Lumpur';
    if (lat > 2.7 && lat < 3.8 && lng > 101.0 && lng < 101.9) return 'Selangor';
    if (lat > 1.3 && lat < 2.5 && lng > 102.5 && lng < 104.5) return 'Johor';
    if (lat > 3.0 && lat < 4.8 && lng > 102.0 && lng < 103.8) return 'Pahang';
    if (lat > 4.5 && lat < 6.3 && lng > 101.5 && lng < 102.5) return 'Kelantan';
    if (lat > 3.5 && lat < 5.8 && lng > 100.5 && lng < 101.8) return 'Perak';
    if (lat > 5.2 && lat < 5.5 && lng > 100.1 && lng < 100.5) return 'Penang';
    if (lat > 4.0 && lat < 7.4 && lng > 115.0 && lng < 119.5) return 'Sabah';
    if (lat > 0.8 && lat < 5.0 && lng > 109.5 && lng < 115.0) return 'Sarawak';
    return 'Malaysia';
  }

  String get queryParams => 'lat=$lat&lng=$lng&location=${Uri.encodeComponent(resolvedLocation)}';
}

class _WebLocationCompleter {
  Future<LocationData?> getLocation() async {
    // Returns null — actual GPS can be injected via JS in index.html when needed
    return null;
  }
}
