import 'package:flutter/material.dart';

/// Semantic color tokens for one brightness. Used as [ThemeExtension] so
/// MaterialApp can lerp light↔dark in one animation (GPU-friendly, no per-widget tweens).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.brand,
    required this.primary,
    required this.white,
    required this.black,
    required this.pageBackground,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSoft,
    required this.surfaceSoftBlue,
    required this.surfaceSoftGreen,
    required this.bgSoftMint,
    required this.bgSoftWhite,
    required this.bgColor,
    required this.border,
    required this.borderSoft,
    required this.borderInput,
    required this.borderCardGreen,
    required this.borderCardBlue,
    required this.divider,
    required this.textColor,
    required this.subTextColor,
    required this.iconMuted,
    required this.textInverse,
    required this.activeColor,
    required this.inactiveColor,
    required this.error,
    required this.destructive,
    required this.successSoft,
    required this.infoSoft,
    required this.functionalSoftBlue,
    required this.functionalSoftBlueIcon,
    required this.functionalSoftOrange,
    required this.functionalSoftOrangeIcon,
    required this.functionalSoftRed,
    required this.functionalSoftRedIcon,
    required this.borderCardRed,
    required this.shadowDark,
    required this.shadowPrimary,
    required this.btnDisabled,
    required this.bottomBarInactiveIcon,
    required this.postShareIcon,
  });

  final Brightness brightness;

  final Color brand;
  final Color primary;

  final Color white;
  final Color black;

  final Color pageBackground;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceSoft;
  final Color surfaceSoftBlue;
  final Color surfaceSoftGreen;

  final Color bgSoftMint;
  final Color bgSoftWhite;
  final Color bgColor;

  final Color border;
  final Color borderSoft;
  final Color borderInput;
  final Color borderCardGreen;
  final Color borderCardBlue;
  final Color divider;

  final Color textColor;
  final Color subTextColor;
  final Color iconMuted;
  final Color textInverse;

  final Color activeColor;
  final Color inactiveColor;
  final Color error;
  final Color destructive;
  final Color successSoft;
  final Color infoSoft;

  final Color functionalSoftBlue;
  final Color functionalSoftBlueIcon;
  final Color functionalSoftOrange;
  final Color functionalSoftOrangeIcon;
  final Color functionalSoftRed;
  final Color functionalSoftRedIcon;
  final Color borderCardRed;

  final Color shadowDark;
  final Color shadowPrimary;

  final Color btnDisabled;
  final Color bottomBarInactiveIcon;
  final Color postShareIcon;

  // ---- aliases (computed, stay in sync with base tokens) ----

  Color get btnBackground => primary;
  Color get btnText => textInverse;
  Color get btnDisabledText => subTextColor;

  Color get bottomBarColor => surface;
  Color get bottomBarActiveIcon => primary;
  Color get bottomBarSegment => primary.withValues(alpha: 0.12);
  Color get bottomBarShadow => primary.withValues(alpha: 0.2);

  Color get fieldBackground => surface;
  Color get fieldBackgroundDisabled => surfaceSoft;
  Color get fieldBorder => borderInput;
  Color get fieldBorderFocused => primary;
  Color get fieldText => textColor;
  Color get fieldTextDisabled => subTextColor;
  Color get fieldHint => subTextColor;
  Color get fieldLabel => subTextColor;
  Color get fieldLabelFocused => textColor;
  Color get fieldIcon => iconMuted;
  Color get fieldIconFocused => primary;
  Color get fieldCursor => primary;
  Color get fieldShadowFocused => primary.withValues(alpha: 0.14);

  Color get postEditorBackground => pageBackground;
  Color get postEditorPanel => surface;
  Color get postEditorCta => primary;
  Color get postEditorOnSurface => textColor;
  Color get postEditorOnSurfaceMuted => subTextColor;
  Color get postEditorOnSurfaceDim => iconMuted;
  Color get postEditorOnSurfaceHint => borderSoft;
  Color get postEditorSliderOverlay => primary.withValues(alpha: 0.14);

  Color get shimmerBase =>
      brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFC8C8CC);

  Color get shimmerHighlight =>
      brightness == Brightness.dark ? const Color(0xFF3A3A3C) : const Color(0xFFF4F4F6);

  static const light = AppPalette(
    brightness: Brightness.light,
    brand: Color(0xffB7F5FE),
    primary: Color(0xFF8BC34A),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    pageBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFFAFAFA),
    surfaceSoft: Color(0xFFF7F7F8),
    surfaceSoftBlue: Color(0xFFF8FAFC),
    surfaceSoftGreen: Color(0xFFF8FAF5),
    bgSoftMint: Color(0xFFF2F8ED),
    bgSoftWhite: Color(0xFFFFFFFF),
    bgColor: Color(0xFF0D140A),
    border: Color(0xFFEEEEEE),
    borderSoft: Color(0xFFE8E8E8),
    borderInput: Color(0xFFE0E0E0),
    borderCardGreen: Color(0xFFE0EBD2),
    borderCardBlue: Color(0xFFC8DDF5),
    divider: Color(0xFFEEEEEE),
    textColor: Color(0xFF1A1D1E),
    subTextColor: Color(0xFF6A6A6A),
    iconMuted: Color(0xFF9E9E9E),
    textInverse: Color(0xFFFFFFFF),
    activeColor: Color(0xFFC5FEB7),
    inactiveColor: Color(0xFF43573D),
    error: Color(0xFFE57373),
    destructive: Color(0xFFC62828),
    successSoft: Color(0xFFEFF8E7),
    infoSoft: Color(0xFFF0F7FF),
    functionalSoftBlue: Color(0xFFE3F0FC),
    functionalSoftBlueIcon: Color(0xFF5B9BD5),
    functionalSoftOrange: Color(0xFFFFF3E0),
    functionalSoftOrangeIcon: Color(0xFFE65100),
    functionalSoftRed: Color(0xFFFFEBEE),
    functionalSoftRedIcon: Color(0xFFE57373),
    borderCardRed: Color(0xFFF5C6CB),
    shadowDark: Color(0xFF000000),
    shadowPrimary: Color(0xFF8BC34A),
    btnDisabled: Color(0xFF1A2418),
    bottomBarInactiveIcon: Color(0xFFA1AAB3),
    postShareIcon: Color(0xFF039BE5),
  );

  /// Dark surfaces stay near-black; brand green kept for recognition.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    brand: Color(0xffB7F5FE),
    primary: Color(0xFF8BC34A),
    white: Color(0xFFFFFFFF),
    black: Color(0xFF000000),
    pageBackground: Color(0xFF0D0D0D),
    surface: Color(0xFF161616),
    surfaceMuted: Color(0xFF121212),
    surfaceSoft: Color(0xFF1C1C1E),
    surfaceSoftBlue: Color(0xFF14181E),
    surfaceSoftGreen: Color(0xFF141A12),
    bgSoftMint: Color(0xFF152016),
    bgSoftWhite: Color(0xFF161616),
    bgColor: Color(0xFF0D140A),
    border: Color(0xFF2A2A2A),
    borderSoft: Color(0xFF242424),
    borderInput: Color(0xFF333333),
    borderCardGreen: Color(0xFF2C3A24),
    borderCardBlue: Color(0xFF243044),
    divider: Color(0xFF2A2A2A),
    textColor: Color(0xFFF2F2F2),
    subTextColor: Color(0xFFA3A3A3),
    iconMuted: Color(0xFF8A8A8A),
    textInverse: Color(0xFF0D0D0D),
    activeColor: Color(0xFF7BC96F),
    inactiveColor: Color(0xFF8FA388),
    error: Color(0xFFEF9A9A),
    destructive: Color(0xFFEF5350),
    successSoft: Color(0xFF1B2A16),
    infoSoft: Color(0xFF152032),
    functionalSoftBlue: Color(0xFF1A2736),
    functionalSoftBlueIcon: Color(0xFF7EB6E0),
    functionalSoftOrange: Color(0xFF2A1E12),
    functionalSoftOrangeIcon: Color(0xFFFFB74D),
    functionalSoftRed: Color(0xFF2A1518),
    functionalSoftRedIcon: Color(0xFFEF9A9A),
    borderCardRed: Color(0xFF4A2A2E),
    shadowDark: Color(0xFF000000),
    shadowPrimary: Color(0xFF8BC34A),
    btnDisabled: Color(0xFF2A2A2A),
    bottomBarInactiveIcon: Color(0xFF7A828A),
    postShareIcon: Color(0xFF4FC3F7),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? brand,
    Color? primary,
    Color? white,
    Color? black,
    Color? pageBackground,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceSoft,
    Color? surfaceSoftBlue,
    Color? surfaceSoftGreen,
    Color? bgSoftMint,
    Color? bgSoftWhite,
    Color? bgColor,
    Color? border,
    Color? borderSoft,
    Color? borderInput,
    Color? borderCardGreen,
    Color? borderCardBlue,
    Color? divider,
    Color? textColor,
    Color? subTextColor,
    Color? iconMuted,
    Color? textInverse,
    Color? activeColor,
    Color? inactiveColor,
    Color? error,
    Color? destructive,
    Color? successSoft,
    Color? infoSoft,
    Color? functionalSoftBlue,
    Color? functionalSoftBlueIcon,
    Color? functionalSoftOrange,
    Color? functionalSoftOrangeIcon,
    Color? functionalSoftRed,
    Color? functionalSoftRedIcon,
    Color? borderCardRed,
    Color? shadowDark,
    Color? shadowPrimary,
    Color? btnDisabled,
    Color? bottomBarInactiveIcon,
    Color? postShareIcon,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      brand: brand ?? this.brand,
      primary: primary ?? this.primary,
      white: white ?? this.white,
      black: black ?? this.black,
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceSoftBlue: surfaceSoftBlue ?? this.surfaceSoftBlue,
      surfaceSoftGreen: surfaceSoftGreen ?? this.surfaceSoftGreen,
      bgSoftMint: bgSoftMint ?? this.bgSoftMint,
      bgSoftWhite: bgSoftWhite ?? this.bgSoftWhite,
      bgColor: bgColor ?? this.bgColor,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      borderInput: borderInput ?? this.borderInput,
      borderCardGreen: borderCardGreen ?? this.borderCardGreen,
      borderCardBlue: borderCardBlue ?? this.borderCardBlue,
      divider: divider ?? this.divider,
      textColor: textColor ?? this.textColor,
      subTextColor: subTextColor ?? this.subTextColor,
      iconMuted: iconMuted ?? this.iconMuted,
      textInverse: textInverse ?? this.textInverse,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      error: error ?? this.error,
      destructive: destructive ?? this.destructive,
      successSoft: successSoft ?? this.successSoft,
      infoSoft: infoSoft ?? this.infoSoft,
      functionalSoftBlue: functionalSoftBlue ?? this.functionalSoftBlue,
      functionalSoftBlueIcon: functionalSoftBlueIcon ?? this.functionalSoftBlueIcon,
      functionalSoftOrange: functionalSoftOrange ?? this.functionalSoftOrange,
      functionalSoftOrangeIcon: functionalSoftOrangeIcon ?? this.functionalSoftOrangeIcon,
      functionalSoftRed: functionalSoftRed ?? this.functionalSoftRed,
      functionalSoftRedIcon: functionalSoftRedIcon ?? this.functionalSoftRedIcon,
      borderCardRed: borderCardRed ?? this.borderCardRed,
      shadowDark: shadowDark ?? this.shadowDark,
      shadowPrimary: shadowPrimary ?? this.shadowPrimary,
      btnDisabled: btnDisabled ?? this.btnDisabled,
      bottomBarInactiveIcon: bottomBarInactiveIcon ?? this.bottomBarInactiveIcon,
      postShareIcon: postShareIcon ?? this.postShareIcon,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? a;

    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      brand: c(brand, other.brand),
      primary: c(primary, other.primary),
      white: c(white, other.white),
      black: c(black, other.black),
      pageBackground: c(pageBackground, other.pageBackground),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      surfaceSoft: c(surfaceSoft, other.surfaceSoft),
      surfaceSoftBlue: c(surfaceSoftBlue, other.surfaceSoftBlue),
      surfaceSoftGreen: c(surfaceSoftGreen, other.surfaceSoftGreen),
      bgSoftMint: c(bgSoftMint, other.bgSoftMint),
      bgSoftWhite: c(bgSoftWhite, other.bgSoftWhite),
      bgColor: c(bgColor, other.bgColor),
      border: c(border, other.border),
      borderSoft: c(borderSoft, other.borderSoft),
      borderInput: c(borderInput, other.borderInput),
      borderCardGreen: c(borderCardGreen, other.borderCardGreen),
      borderCardBlue: c(borderCardBlue, other.borderCardBlue),
      divider: c(divider, other.divider),
      textColor: c(textColor, other.textColor),
      subTextColor: c(subTextColor, other.subTextColor),
      iconMuted: c(iconMuted, other.iconMuted),
      textInverse: c(textInverse, other.textInverse),
      activeColor: c(activeColor, other.activeColor),
      inactiveColor: c(inactiveColor, other.inactiveColor),
      error: c(error, other.error),
      destructive: c(destructive, other.destructive),
      successSoft: c(successSoft, other.successSoft),
      infoSoft: c(infoSoft, other.infoSoft),
      functionalSoftBlue: c(functionalSoftBlue, other.functionalSoftBlue),
      functionalSoftBlueIcon: c(functionalSoftBlueIcon, other.functionalSoftBlueIcon),
      functionalSoftOrange: c(functionalSoftOrange, other.functionalSoftOrange),
      functionalSoftOrangeIcon: c(functionalSoftOrangeIcon, other.functionalSoftOrangeIcon),
      functionalSoftRed: c(functionalSoftRed, other.functionalSoftRed),
      functionalSoftRedIcon: c(functionalSoftRedIcon, other.functionalSoftRedIcon),
      borderCardRed: c(borderCardRed, other.borderCardRed),
      shadowDark: c(shadowDark, other.shadowDark),
      shadowPrimary: c(shadowPrimary, other.shadowPrimary),
      btnDisabled: c(btnDisabled, other.btnDisabled),
      bottomBarInactiveIcon: c(bottomBarInactiveIcon, other.bottomBarInactiveIcon),
      postShareIcon: c(postShareIcon, other.postShareIcon),
    );
  }
}
