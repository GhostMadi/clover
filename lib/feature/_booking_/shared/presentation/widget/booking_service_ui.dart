import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Акцент продукта «Запись» — жёлтый сервисный стиль.
///
/// Менять цвет: `AppPalette.functionalSoftYellow` / `functionalSoftYellowIcon`
/// (и `borderCardYellow`) — UI с [kBookingService] подтянется сам.
const AppServiceKind kBookingService = AppServiceKind.booking;

AppServiceAccent bookingServiceAccent(AppPalette colors) =>
    colors.serviceAccent(kBookingService);

/// Лоадер записи (жёлтый акцент).
class BookingLoader extends StatelessWidget {
  const BookingLoader({super.key, this.strokeWidth = 2.5, this.size});

  final double strokeWidth;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = bookingServiceAccent(context.colors).icon;
    final indicator = CircularProgressIndicator(strokeWidth: strokeWidth, color: color);
    if (size == null) return Center(child: indicator);
    return Center(
      child: SizedBox(width: size, height: size, child: indicator),
    );
  }
}

/// Основная CTA записи.
class BookingPrimaryButton extends StatelessWidget {
  const BookingPrimaryButton({
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
      service: kBookingService,
      height: height,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isExpanded: isExpanded,
      interactive: interactive,
      child: child,
    );
  }
}

/// Поле с жёлтым акцентом записи.
class BookingField extends StatelessWidget {
  const BookingField({
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
      service: kBookingService,
    );
  }
}

/// Свитч с жёлтым акцентом записи.
class BookingSwitchRow extends StatelessWidget {
  const BookingSwitchRow({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.enabled = true,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSwitchRow(
      title: title,
      subtitle: subtitle,
      value: value,
      enabled: enabled,
      onChanged: onChanged,
      service: kBookingService,
    );
  }
}
