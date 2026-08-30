import 'package:flutter/material.dart';

/// Палитра онбординга Clover.
abstract final class OnboardingColors {
  /// 🟢 Clover Green (primary)
  static const cloverGreen = Color(0xFF8BC34A);

  /// 🟡 Warm Yellow
  static const warmYellow = Color(0xFFF5C542);

  /// 🩷 Coral Pink
  static const coralPink = Color(0xFFFF6B8A);

  /// 🩵 Soft Blue
  static const softBlue = Color(0xFF5EC8F2);

  /// 🟣 Lavender
  static const lavender = Color(0xFFB39DDB);

  static const accents = <Color>[
    cloverGreen,
    warmYellow,
    coralPink,
    softBlue,
    lavender,
  ];
}
