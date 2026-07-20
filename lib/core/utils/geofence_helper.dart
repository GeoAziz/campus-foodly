import 'dart:math';

/// Helper class for geofence operations
class GeofenceHelper {
  /// Calculate distance between two coordinates in meters using Haversine formula
  ///
  /// Returns distance in meters
  static double calculateDistance({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusMeters = 6371000.0; // Earth's radius in meters

    final dLat = _toRadians(toLat - fromLat);
    final dLng = _toRadians(toLng - fromLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(fromLat)) *
            cos(_toRadians(toLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Check if a location is within campus geofence
  ///
  /// Returns true if within radius, false otherwise
  static bool isWithinGeofence({
    required double userLat,
    required double userLng,
    required double campusLat,
    required double campusLng,
    required int radiusMeters,
  }) {
    final distance = calculateDistance(
      fromLat: userLat,
      fromLng: userLng,
      toLat: campusLat,
      toLng: campusLng,
    );
    return distance <= radiusMeters;
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)}km';
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
