import 'package:clover/core/resources/style.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static const animationDuration = Duration(milliseconds: 380);
  static const animationCurve = Curves.easeInOutCubic;

  static ThemeData light() => _base(AppPalette.light);

  static ThemeData dark() => _base(AppPalette.dark);

  static ThemeData _base(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.pageBackground,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        onPrimary: palette.textInverse,
        secondary: palette.brand,
        onSecondary: palette.textColor,
        error: palette.error,
        onError: palette.textInverse,
        surface: palette.surface,
        onSurface: palette.textColor,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.primary),
      dividerColor: palette.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.textColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyle.base(20, color: palette.textColor, fontWeight: FontWeight.w500),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceSoft,
        contentTextStyle: AppTextStyle.base(14, color: palette.textColor),
      ),
    );
  }
}
