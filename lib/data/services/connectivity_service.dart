import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

typedef ConnectivityListener = void Function(List<ConnectivityResult>);

/// Service to manage device connectivity state
/// Provides real-time monitoring of network connectivity with multiple listeners support
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static final Logger _logger = Logger();

  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult>? _lastResult;

  // Support multiple listeners
  final List<ConnectivityListener> _listeners = [];

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      _lastResult = await _connectivity.checkConnectivity();
      _logger.i('Initial connectivity: $_lastResult');

      _connectivity.onConnectivityChanged.listen(
        (result) {
          _logger.i('Connectivity changed: $result');
          _lastResult = result;
          _notifyListeners(result);
        },
        onError: (error) {
          _logger.e('Connectivity error: $error');
        },
        onDone: () {
          _logger.i('Connectivity stream closed');
        },
      );
    } catch (e) {
      _logger.e('Failed to initialize connectivity: $e');
    }
  }

  /// Check if device is currently online
  bool get isOnline {
    return _lastResult != null &&
        _lastResult!.isNotEmpty &&
        !_lastResult!.contains(ConnectivityResult.none);
  }

  /// Get current connectivity status
  List<ConnectivityResult>? get currentStatus => _lastResult;

  /// Add a listener for connectivity changes
  void addListener(ConnectivityListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      _logger.d('Connectivity listener added. Total listeners: ${_listeners.length}');
    }
  }

  /// Remove a specific listener
  void removeListener(ConnectivityListener listener) {
    _listeners.remove(listener);
    _logger.d('Connectivity listener removed. Total listeners: ${_listeners.length}');
  }

  /// Remove all listeners (for cleanup on app lifecycle)
  void removeAllListeners() {
    _listeners.clear();
    _logger.d('All connectivity listeners cleared');
  }

  /// Notify all registered listeners of connectivity change
  void _notifyListeners(List<ConnectivityResult> result) {
    for (final listener in List.of(_listeners)) {
      try {
        listener(result);
      } catch (e) {
        _logger.e('Error notifying listener: $e');
      }
    }
  }

  /// Retry operation with exponential backoff
  Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retries = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        if (!isOnline) {
          throw ConnectivityException('Device is offline');
        }

        return await operation();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          _logger.e('Max retries exceeded for operation: $e');
          rethrow;
        }

        _logger.w(
            'Operation failed, retrying in $delay. Attempt $retries/$maxRetries');
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }
}

/// Exception for connectivity-related errors
class ConnectivityException implements Exception {
  ConnectivityException(this.message);
  final String message;

  @override
  String toString() => message;
}
