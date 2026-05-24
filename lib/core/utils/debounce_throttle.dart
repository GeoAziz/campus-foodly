import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debounces rapid function calls, useful for search input and other frequent events
class Debouncer {
  final Duration delay;
  Timer? _timer;
  final VoidCallback onDebounce;

  Debouncer({
    required this.delay,
    required this.onDebounce,
  });

  void call() {
    _timer?.cancel();
    _timer = Timer(delay, onDebounce);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}

/// Throttles function calls to execute at most once every [interval]
class Throttler {
  final Duration interval;
  DateTime? _lastExecuted;
  final Future<void> Function() callback;

  Throttler({
    required this.interval,
    required this.callback,
  });

  Future<void> call() async {
    final now = DateTime.now();
    final lastExecution = _lastExecuted;

    if (lastExecution == null || now.difference(lastExecution) >= interval) {
      _lastExecuted = now;
      await callback();
    }
  }

  void reset() {
    _lastExecuted = null;
  }
}
