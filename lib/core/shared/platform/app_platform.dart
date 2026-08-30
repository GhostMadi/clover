import 'package:flutter/foundation.dart';

enum AppPlatformType { ios, android }

/// Платформа устройства — от неё строим «нативный» вид shared-виджетов.
///
/// Не использовать `dart:io` `Platform.isIOS` в UI: ломается на web и в тестах.
abstract final class AppPlatform {
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// На не-мобильных платформах (web / desktop) считаем Material базой.
  static AppPlatformType get current => isIOS ? AppPlatformType.ios : AppPlatformType.android;
}
