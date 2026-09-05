import 'package:clover/core/debug/app_shake_logger_config.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Единый Talker для приложения (консоль + история + TalkerScreen).
final Talker appTalker = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: AppShakeLoggerConfig.enabled,
    useHistory: true,
    useConsoleLogs: true,
    maxHistoryItems: AppShakeLoggerConfig.maxEntries,
  ),
);
