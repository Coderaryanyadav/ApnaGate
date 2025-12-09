import 'package:flutter/foundation.dart';

/// Centralized error logging service
class ErrorLogger {
  static void log(dynamic error, {StackTrace? stackTrace, String? context}) {
    if (kDebugMode) {
      debugPrint('❌ ERROR${context != null ? ' [$context]' : ''}: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
    
    // TODO: Send to crash reporting service (Sentry/Firebase Crashlytics)
    // Sentry.captureException(error, stackTrace: stackTrace);
  }

  static void logWarning(String message, {String? context}) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING${context != null ? ' [$context]' : ''}: $message');
    }
  }

  static void logInfo(String message, {String? context}) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO${context != null ? ' [$context]' : ''}: $message');
    }
  }
}
