import 'package:clover/core/debug/app_shake_logger_config.dart';
import 'package:clover/core/debug/app_talker.dart';

/// Тонкая обёртка над [appTalker] — удобные вызовы из фич / HTTP.
class AppLog {
  AppLog._();

  static void d(String message, {String? tag}) {
    if (!AppShakeLoggerConfig.enabled) return;
    appTalker.debug(_withTag(tag, message));
  }

  static void i(String message, {String? tag}) {
    if (!AppShakeLoggerConfig.enabled) return;
    appTalker.info(_withTag(tag, message));
  }

  static void w(String message, {String? tag}) {
    if (!AppShakeLoggerConfig.enabled) return;
    appTalker.warning(_withTag(tag, message));
  }

  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!AppShakeLoggerConfig.enabled) return;
    if (error != null) {
      appTalker.handle(error, stackTrace, _withTag(tag, message));
      return;
    }
    appTalker.error(_withTag(tag, message), null, stackTrace);
  }

  static void clear() {
    if (!AppShakeLoggerConfig.enabled) return;
    appTalker.cleanHistory();
  }

  static String _withTag(String? tag, String message) {
    if (tag == null || tag.isEmpty) return message;
    return '[$tag] $message';
  }
}
