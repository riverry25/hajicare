import 'package:flutter/foundation.dart';

/// Centralized lightweight logger for HajiCare.
/// Best-practice replacement for scattered debugPrint and print statements.
///
/// - In release mode, non-critical logging is completely stripped/bypassed.
/// - In debug mode:
///   - [AppLogger.error]: Logs critical errors with optional stack traces.
///   - [AppLogger.warn]: Logs warning conditions.
///   - [AppLogger.info]: Logs milestone lifecycle events (auth state, room connection).
///   - [AppLogger.debug]: High-frequency / granular traces (suppressed by default to prevent console spam).
class AppLogger {
  AppLogger._();

  /// Set to true only when deep-debugging frame-by-frame or tick-by-tick events.
  /// Default is false to keep the debug console clean, snappy, and readable.
  static bool verbose = false;

  /// Logs critical errors or exceptions.
  static void error(Object error, {String? tag, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final prefix = tag != null ? '❌ [$tag] ERROR: ' : '❌ ERROR: ';
      debugPrint('$prefix$error');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  /// Logs warning conditions that don't halt execution.
  static void warn(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '⚠️ [$tag] ' : '⚠️ ';
      debugPrint('$prefix$message');
    }
  }

  /// Logs important operational milestones (e.g., room connected, route ready).
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? 'ℹ️ [$tag] ' : 'ℹ️ ';
      debugPrint('$prefix$message');
    }
  }

  /// Logs high-frequency or detailed traces (only emitted when [verbose] is true).
  static void debug(String message, {String? tag}) {
    if (kDebugMode && verbose) {
      final prefix = tag != null ? '🔍 [$tag] ' : '🔍 ';
      debugPrint('$prefix$message');
    }
  }
}
