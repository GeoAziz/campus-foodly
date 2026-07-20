import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Exception for location service errors
class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Position? _cachedPosition;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get current position with caching
  Future<Position> getCurrentPosition({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh &&
          _cachedPosition != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        _logger.d('Using cached location');
        return _cachedPosition!;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location services are disabled. '
            'Please enable location in device settings.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationException('Location permission not granted. '
            'Please enable location permissions in app settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      // Cache the position
      _cachedPosition = position;
      _cacheTime = DateTime.now();
      _logger.i('Location updated: ${position.latitude}, ${position.longitude}');

      return position;
    } catch (e) {
      if (e is LocationException) rethrow;
      _logger.e('Error getting location: $e');
      throw LocationException('Failed to get device location: $e');
    }
  }

  /// Clear cached location
  void clearCache() {
    _cachedPosition = null;
    _cacheTime = null;
    _logger.d('Location cache cleared');
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      _logger.e('Error checking permission: $e');
      return false;
    }
  }
}
