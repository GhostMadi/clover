import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class BookingListPeriodBanner extends StatelessWidget {
  const BookingListPeriodBanner({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.functionalSoftBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.borderCardBlue.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.calendarToday.icon, size: 16, color: context.colors.functionalSoftBlueIcon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyle.base(13, color: context.colors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
