import 'package:clover/core/resources/colors.dart';
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
        color: AppColors.functionalSoftBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCardBlue.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.functionalSoftBlueIcon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyle.base(13, color: AppColors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
