import 'package:clover/core/theme/app_color_binding.dart';
import 'package:clover/core/theme/app_colors_scope.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

export 'package:clover/core/theme/app_colors_scope.dart' show AppColorsContext, AppColorsScope;
export 'package:clover/core/theme/app_palette.dart' show AppPalette;

/// Semantic colors. Values follow the active theme via [AppColorBinding]
/// (updated each MaterialApp theme animation frame).
///
/// New widgets: prefer `context.colors` / [AppColors.of] so they rebuild during lerp.
abstract final class AppColors {
  static AppPalette of(BuildContext context) => AppColorsScope.of(context);

  static AppPalette get _p => AppColorBinding.palette;

  // Brand
  static Color get brand => _p.brand;
  static Color get primary => _p.primary;

  // Surfaces
  static Color get white => _p.white;
  static Color get black => _p.black;
  static Color get pageBackground => _p.pageBackground;
  static Color get surface => _p.surface;
  static Color get surfaceMuted => _p.surfaceMuted;
  static Color get surfaceSoft => _p.surfaceSoft;
  static Color get surfaceSoftBlue => _p.surfaceSoftBlue;
  static Color get surfaceSoftGreen => _p.surfaceSoftGreen;

  // Background accents
  static Color get bgSoftMint => _p.bgSoftMint;
  static Color get bgSoftWhite => _p.bgSoftWhite;
  static Color get bgColor => _p.bgColor;

  // Borders
  static Color get border => _p.border;
  static Color get borderSoft => _p.borderSoft;
  static Color get borderInput => _p.borderInput;
  static Color get borderCardGreen => _p.borderCardGreen;
  static Color get borderCardBlue => _p.borderCardBlue;
  static Color get divider => _p.divider;

  // Text
  static Color get textColor => _p.textColor;
  static Color get subTextColor => _p.subTextColor;
  static Color get iconMuted => _p.iconMuted;
  static Color get textInverse => _p.textInverse;

  // States
  static Color get activeColor => _p.activeColor;
  static Color get inactiveColor => _p.inactiveColor;
  static Color get error => _p.error;
  static Color get destructive => _p.destructive;
  static Color get successSoft => _p.successSoft;
  static Color get infoSoft => _p.infoSoft;
  static Color get functionalSoftBlue => _p.functionalSoftBlue;
  static Color get functionalSoftBlueIcon => _p.functionalSoftBlueIcon;
  static Color get functionalSoftOrange => _p.functionalSoftOrange;
  static Color get functionalSoftOrangeIcon => _p.functionalSoftOrangeIcon;
  static Color get functionalSoftRed => _p.functionalSoftRed;
  static Color get functionalSoftRedIcon => _p.functionalSoftRedIcon;
  static Color get borderCardRed => _p.borderCardRed;

  // Shadows
  static Color get shadowDark => _p.shadowDark;
  static Color get shadowPrimary => _p.shadowPrimary;

  // Buttons / nav
  static Color get btnBackground => _p.btnBackground;
  static Color get btnText => _p.btnText;
  static Color get btnDisabled => _p.btnDisabled;
  static Color get btnDisabledText => _p.btnDisabledText;
  static Color get bottomBarColor => _p.bottomBarColor;
  static Color get bottomBarActiveIcon => _p.bottomBarActiveIcon;
  static Color get bottomBarInactiveIcon => _p.bottomBarInactiveIcon;
  static Color get bottomBarSegment => _p.bottomBarSegment;
  static Color get bottomBarShadow => _p.bottomBarShadow;

  // Fields
  static Color get fieldBackground => _p.fieldBackground;
  static Color get fieldBackgroundDisabled => _p.fieldBackgroundDisabled;
  static Color get fieldBorder => _p.fieldBorder;
  static Color get fieldBorderFocused => _p.fieldBorderFocused;
  static Color get fieldText => _p.fieldText;
  static Color get fieldTextDisabled => _p.fieldTextDisabled;
  static Color get fieldHint => _p.fieldHint;
  static Color get fieldLabel => _p.fieldLabel;
  static Color get fieldLabelFocused => _p.fieldLabelFocused;
  static Color get fieldIcon => _p.fieldIcon;
  static Color get fieldIconFocused => _p.fieldIconFocused;
  static Color get fieldCursor => _p.fieldCursor;
  static Color get fieldShadowFocused => _p.fieldShadowFocused;

  // Post editor
  static Color get postEditorBackground => _p.postEditorBackground;
  static Color get postEditorPanel => _p.postEditorPanel;
  static Color get postEditorCta => _p.postEditorCta;
  static Color get postEditorOnSurface => _p.postEditorOnSurface;
  static Color get postEditorOnSurfaceMuted => _p.postEditorOnSurfaceMuted;
  static Color get postEditorOnSurfaceDim => _p.postEditorOnSurfaceDim;
  static Color get postEditorOnSurfaceHint => _p.postEditorOnSurfaceHint;
  static Color get postEditorSliderOverlay => _p.postEditorSliderOverlay;

  // Misc
  static Color get postShareIcon => _p.postShareIcon;
}
