import 'package:clover/core/resources/app_service_accent.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Акцент продукта «Посещаемость» — синий сервисный стиль.
const AppServiceKind kAttendanceService = AppServiceKind.attendance;

AppServiceAccent attendanceServiceAccent(AppPalette colors) =>
    colors.serviceAccent(kAttendanceService);

/// Жёлтый акцент посещаемости: ожидание, опоздание, предупреждения.
({Color surface, Color icon}) attendanceYellowAccent(AppPalette colors) => (
      surface: colors.functionalSoftYellow,
      icon: colors.functionalSoftYellowIcon,
    );

({Color surface, Color icon}) attendanceWaitingAccent(AppPalette colors) =>
    attendanceYellowAccent(colors);

/// Основная CTA посещаемости (синяя, не брендовая зелёная).
class AttendancePrimaryButton extends StatelessWidget {
  const AttendancePrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 56.0,
    this.borderRadius = 18.0,
    this.isLoading = false,
    this.isExpanded = false,
    this.interactive = true,
    this.child,
  });

  final String text;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final bool isExpanded;
  final bool interactive;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onTap: onTap,
      service: kAttendanceService,
      height: height,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isExpanded: isExpanded,
      interactive: interactive,
      child: child,
    );
  }
}

/// Поле ввода с синим акцентом посещаемости.
class AttendanceField extends StatelessWidget {
  const AttendanceField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.validator,
    this.inputFormatters,
    this.isEnabled = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return AppField(
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      isEnabled: isEnabled,
      service: kAttendanceService,
    );
  }
}

/// Строка меню посещаемости с сервисным синим icon-tile по умолчанию.
class AttendanceServiceTile extends StatelessWidget {
  const AttendanceServiceTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.destructive = false,
    this.filled = false,
    this.showDivider = false,
    this.borderRadius = 5,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;
  final bool destructive;
  final bool filled;
  final bool showDivider;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final accent = attendanceServiceAccent(context.colors);

    return AppTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      icon: icon,
      iconColor: destructive ? null : (iconColor ?? accent.icon),
      iconBackgroundColor: destructive ? null : (iconBackgroundColor ?? accent.soft),
      trailing: trailing,
      showChevron: showChevron,
      onTap: onTap,
      enabled: enabled,
      selected: selected,
      destructive: destructive,
      filled: filled,
      showDivider: showDivider,
      borderRadius: borderRadius,
    );
  }
}

/// Bottom sheet посещаемости — синий акцент заголовка и ручки.
abstract final class AttendanceBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    Axis actionsAxis = Axis.vertical,
    bool barrierDismissible = true,
    bool upperCaseTitle = true,
    bool showCloseButton = false,
    double? contentHeight,
    double contentBottomSpacing = 18,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    EdgeInsetsGeometry sheetOuterPadding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
    double? sheetWidth,
    bool postFeedSurface = false,
    bool expandBody = false,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      title: title,
      content: content,
      actions: actions,
      actionsAxis: actionsAxis,
      barrierDismissible: barrierDismissible,
      upperCaseTitle: upperCaseTitle,
      showCloseButton: showCloseButton,
      contentHeight: contentHeight,
      contentBottomSpacing: contentBottomSpacing,
      contentPadding: contentPadding,
      sheetOuterPadding: sheetOuterPadding,
      sheetWidth: sheetWidth,
      postFeedSurface: postFeedSurface,
      expandBody: expandBody,
      service: kAttendanceService,
    );
  }
}
