import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_pill_button.dart';
import 'package:flutter/material.dart';

/// Правая accessory-кнопка вкладки «Профиль» на дашборде.
class ProfileDashboardAccessories extends StatelessWidget {
  const ProfileDashboardAccessories({super.key, required this.onMoreTap});

  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return AppFunctionalPillButton(
      customColor: context.colors.functionalSoftBlue,
      icon: AppIcons.more.icon,
      iconColor: context.colors.functionalSoftBlueIcon,
      onTap: onMoreTap,
    );
  }
}
