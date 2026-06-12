import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Логи вызовов Edge Functions (отдельно от [SupabaseLoggingHttpClient]).
///
/// В релизе по умолчанию выключено. В debug можно отключить шум: [enabled] = false.
abstract final class EdgeFunctionLog {
  /// `false` — не писать в консоль / DevTools (имя `EdgeFn`).
  static bool enabled = kDebugMode;

  static void d(String message, {String name = 'EdgeFn'}) {
    if (!enabled) return;
    developer.log(message, name: name);
  }

  static void e(Object error, StackTrace stackTrace, String message, {String name = 'EdgeFn'}) {
    if (!enabled) return;
    developer.log(message, name: name, error: error, stackTrace: stackTrace, level: 1000);
  }
}
