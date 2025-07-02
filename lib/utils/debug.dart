import 'package:flutter/foundation.dart';

/// Debug utility function for logging messages with timestamp and context
void debug(String message) {
  if (kDebugMode) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] DEBUG: $message');
  }
} 