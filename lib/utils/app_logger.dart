import 'package:flutter/foundation.dart';

class AppLogger {
  static void v(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[VERBOSE] $message ${error != null ? '\nError: $error' : ''}');
    }
  }

  static void d(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[DEBUG] $message ${error != null ? '\nError: $error' : ''}');
    }
  }

  static void i(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[INFO] $message ${error != null ? '\nError: $error' : ''}');
  }

  static void w(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[WARN] $message ${error != null ? '\nError: $error' : ''}');
  }

  static void e(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[ERROR] $message ${error != null ? '\nError: $error' : ''}');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
