import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class NotificationSectionHeader extends StatelessWidget {
  const NotificationSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
