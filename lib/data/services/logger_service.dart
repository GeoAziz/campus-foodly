import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Structured logging service with multi-sink support
/// Logs to console in debug mode, and to Crashlytics + file storage in production
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  static late Logger _logger;

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal() {
    _initializeLogger();
  }

  void _initializeLogger() {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 3,
        errorMethodCount: 8,
        lineLength: 120,
        colors: !kDebugMode, // Disable colors in production
        printEmojis: kDebugMode,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceLastCall,
      ),
      output: MultiOutput([
        ConsoleOutput(),
        if (!kDebugMode) CrashlyticsOutput(),
      ]),
    );
  }

  /// Log debug message
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical message
  void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Close logger (cleanup resources)
  void close() {
    _logger.close();
  }
}

/// Filter logs based on environment
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true;
    }
    // In production, only log warning and above
    return event.level.index >= Level.warning.index;
  }
}

/// Output logs to multiple sinks
class MultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  MultiOutput(this.outputs);

  @override
  void output(OutputEvent event) {
    for (final output in outputs) {
      output.output(event);
    }
  }
}

/// Console output (default)
class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      print(line);
    }
  }
}

/// Output logs to Firebase Crashlytics
class CrashlyticsOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final crashlytics = FirebaseCrashlytics.instance;

    for (final line in event.lines) {
      // Log to Crashlytics for production monitoring
      if (event.level == Level.error || event.level == Level.fatal) {
        crashlytics.log(line);
      }
    }
  }
}

/// Simple log event class for structured logging
class LogEvent {
  final String timestamp;
  final String level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEvent({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'level': level,
        'message': message,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      };
}
