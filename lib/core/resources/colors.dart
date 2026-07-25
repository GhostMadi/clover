import 'package:flutter/material.dart';

abstract class AppColors {
  // ==========================================================================
  // BRAND (identity layer)
  // ==========================================================================

  static const Color brand = Color(0xffB7F5FE); // aqua-mint
  static const Color primary = Color(0xFF8BC34A); // fresh green

  // ==========================================================================
  // SURFACES (background system)
  // ==========================================================================

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceMuted = Color(0xFFFAFAFA);
  static const Color surfaceSoft = Color(0xFFF7F7F8);
  static const Color surfaceSoftBlue = Color(0xFFF8FAFC);
  static const Color surfaceSoftGreen = Color(0xFFF8FAF5);

  // ==========================================================================
  // BACKGROUND ACCENTS (flat decorative layers)
  // ==========================================================================

  static const Color bgSoftMint = Color(0xFFF2F8ED);
  static const Color bgSoftWhite = Color(0xFFFFFFFF);
  static const Color bgColor = Color(0xFF0D140A); // optional dark base

  // ==========================================================================
  // BORDERS & DIVIDERS
  // ==========================================================================

  static const Color border = Color(0xFFEEEEEE);
  static const Color borderSoft = Color(0xFFE8E8E8);
  static const Color borderInput = Color(0xFFE0E0E0);

  static const Color borderCardGreen = Color(0xFFE0EBD2);
  static const Color borderCardBlue = Color(0xFFC8DDF5);

  static const Color divider = Color(0xFFEEEEEE);

  // ==========================================================================
  // TEXT SYSTEM
  // ==========================================================================

  static const Color textColor = Color(0xFF1A1D1E);
  static const Color subTextColor = Color(0xFF6A6A6A);
  static const Color iconMuted = Color(0xFF9E9E9E);

  static const Color textInverse = Color(0xFFFFFFFF);

  // ==========================================================================
  // STATES
  // ==========================================================================

  static const Color activeColor = Color(0xFFC5FEB7);
  static const Color inactiveColor = Color(0xFF43573D);

  static const Color error = Color(0xFFE57373);
  static const Color destructive = Color(0xFFC62828);

  static const Color successSoft = Color(0xFFEFF8E7);
  static const Color infoSoft = Color(0xFFF0F7FF);

  /// Мягкий голубой для вторичных action-кнопок (фильтр и т.п.).
  static const Color functionalSoftBlue = Color(0xFFE3F0FC);
  static const Color functionalSoftBlueIcon = Color(0xFF5B9BD5);

  /// Мягкий оранжевый для вторичных action-кнопок (уведомления и т.п.).
  static const Color functionalSoftOrange = Color(0xFFFFF3E0);
  static const Color functionalSoftOrangeIcon = Color(0xFFE65100);

  /// Мягкий красный для деструктивных, но не alarm action-кнопок.
  static const Color functionalSoftRed = Color(0xFFFFEBEE);
  static const Color functionalSoftRedIcon = Color(0xFFE57373);
  static const Color borderCardRed = Color(0xFFF5C6CB);

  // ==========================================================================
  // SHADOWS
  // ==========================================================================

  static const Color shadowDark = Color(0xFF000000);
  static const Color shadowPrimary = Color(0xFF8BC34A);

  // ==========================================================================
  // INTERACTIVE ELEMENTS (buttons, inputs, nav)
  // ==========================================================================

  // Buttons
  static const Color btnBackground = primary;
  static const Color btnText = textInverse;

  static const Color btnDisabled = Color(0xFF1A2418);
  static const Color btnDisabledText = subTextColor;

  // Bottom bar
  static const Color bottomBarColor = white;
  static const Color bottomBarActiveIcon = primary;
  static const Color bottomBarInactiveIcon = Color(0xFFA1AAB3);

  static Color bottomBarSegment = primary.withValues(alpha: 0.12);

  static Color bottomBarShadow = primary.withValues(alpha: 0.2);

  // Inputs (field system)
  static const Color fieldBackground = surface;
  static const Color fieldBackgroundDisabled = surfaceSoft;

  static const Color fieldBorder = borderInput;
  static const Color fieldBorderFocused = primary;

  static const Color fieldText = textColor;
  static const Color fieldTextDisabled = subTextColor;

  static const Color fieldHint = subTextColor;
  static const Color fieldLabel = subTextColor;
  static const Color fieldLabelFocused = textColor;

  static const Color fieldIcon = iconMuted;
  static const Color fieldIconFocused = primary;

  static const Color fieldCursor = primary;

  static Color fieldShadowFocused = primary.withValues(alpha: 0.14);

  // ==========================================================================
  // POST EDITOR (feature-specific tokens)
  // ==========================================================================

  static const Color postEditorBackground = pageBackground;
  static const Color postEditorPanel = surface;

  static const Color postEditorCta = primary;

  static const Color postEditorOnSurface = textColor;
  static const Color postEditorOnSurfaceMuted = subTextColor;
  static const Color postEditorOnSurfaceDim = iconMuted;
  static const Color postEditorOnSurfaceHint = borderSoft;

  static Color postEditorSliderOverlay = primary.withValues(alpha: 0.14);

  // ==========================================================================
  // MISC
  // ==========================================================================

  static const Color postShareIcon = Color(0xFF039BE5);
}
