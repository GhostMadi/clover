import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Предполагаем, что у вас используется flutter_screenutil для адаптивности (.sp)
// import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyle {
  static TextStyle base(
    double size, {
    double? height,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: size, // или size.sp, если расширение подключено
    color: color,
    fontWeight: fontWeight ?? FontWeight.w300,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Эмодзи / символы вне Manrope (системный шрифт).
  static TextStyle emoji(double size, {double height = 1}) => TextStyle(
        fontSize: size,
        height: height,
      );
}
