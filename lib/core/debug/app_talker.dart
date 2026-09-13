import 'package:clover/core/debug/app_shake_logger_config.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Единый Talker для приложения (история + TalkerScreen по встряске).
final Talker appTalker = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: AppShakeLoggerConfig.enabled,
    useHistory: true,
    // Консоль Xcode/Android Studio — только в debug; иначе дубли и «каши» из print.
    useConsoleLogs: kDebugMode,
    maxHistoryItems: AppShakeLoggerConfig.maxEntries,
  ),
);
