import 'package:flutter/foundation.dart';

class TLoggerHelper {
  TLoggerHelper._();

  static void debug(String message) {
    if (!kReleaseMode) {
      debugPrint('DEBUG: $message');
    }
  }

  static void info(String message) {
    if (!kReleaseMode) {
      debugPrint('INFO: $message');
    }
  }

  static void warning(String message) {
    if (!kReleaseMode) {
      debugPrint('WARNING: $message');
    }
  }

  static void error(String message, [dynamic error]) {
    if (!kReleaseMode) {
      debugPrint('ERROR: $message');
      if (error != null) {
        debugPrint('  → $error');
      }
    }
  }

  static void success(String message) {
    if (!kReleaseMode) {
      debugPrint('SUCCESS: $message');
    }
  }

  static void network(String message) {
    if (!kReleaseMode) {
      debugPrint('NETWORK: $message');
    }
  }

  static void api(String message) {
    if (!kReleaseMode) {
      debugPrint('API: $message');
    }
  }

  static void auth(String message) {
    if (!kReleaseMode) {
      debugPrint('AUTH: $message');
    }
  }

  static void database(String message) {
    if (!kReleaseMode) {
      debugPrint('DB: $message');
    }
  }

  static void navigation(String message) {
    if (!kReleaseMode) {
      debugPrint('NAV: $message');
    }
  }

  static void custom(String tag, String message) {
    if (!kReleaseMode) {
      debugPrint('[$tag]: $message');
    }
  }

  static void printObject(String title, dynamic object) {
    if (!kReleaseMode) {
      debugPrint('$title: $object');
    }
  }

  static void printSeparator() {
    if (!kReleaseMode) {
      debugPrint('─' * 50);
    }
  }

  static void printJson(String title, String json) {
    if (!kReleaseMode) {
      debugPrint('$title: $json');
    }
  }
}