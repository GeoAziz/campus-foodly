import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Service to manage device connectivity state
/// Provides real-time monitoring of network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static final Logger _logger = Logger();
  
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult? _lastResult;
  
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
      );
    } catch (e) {
      _logger.e('Failed to initialize connectivity: $e');
    }
  }

  /// Check if device is currently online
  bool get isOnline {
    return _lastResult != null && _lastResult != ConnectivityResult.none;
  }

  /// Get current connectivity status
  ConnectivityResult? get currentStatus => _lastResult;

  /// Listen to connectivity changes
  void Function(ConnectivityResult)? _listener;
  
  void addListener(Function(ConnectivityResult) listener) {
    _listener = listener;
  }

  void removeListener() {
    _listener = null;
  }

  void _notifyListeners(ConnectivityResult result) {
    _listener?.call(result);
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
        return await operation();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          _logger.e('Max retries exceeded for operation: $e');
          rethrow;
        }

        _logger.w('Operation failed, retrying in $delay. Attempt $retries/$maxRetries');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }
}
