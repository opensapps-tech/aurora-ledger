// TODO: Replace with a production logging solution (e.g. logger package).
// In release builds all log output must be stripped.
// NEVER log sensitive data: private keys, group keys, operation payloads.

import 'package:flutter/foundation.dart';

/// Minimal structured logger for Aurora Ledger.
class AuroraLogger {
  const AuroraLogger(this._tag);

  final String _tag;

  void debug(String message) {
    if (kDebugMode) debugPrint('[$_tag] DEBUG: $message');
  }

  void info(String message) {
    if (kDebugMode) debugPrint('[$_tag] INFO:  $message');
  }

  void warn(String message) {
    if (kDebugMode) debugPrint('[$_tag] WARN:  $message');
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$_tag] ERROR: $message');
      if (error != null) debugPrint('  cause: $error');
      if (stackTrace != null) debugPrint('  stack: $stackTrace');
    }
  }
}
