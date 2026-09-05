import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

enum PushDevicePlatform {
  ios,
  android;

  String get storageValue => name;

  static PushDevicePlatform? get current {
    if (kIsWeb) return null;
    if (Platform.isIOS) return PushDevicePlatform.ios;
    if (Platform.isAndroid) return PushDevicePlatform.android;
    return null;
  }
}
