import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class ProfileActiveFiltersRow extends StatelessWidget {
  const ProfileActiveFiltersRow({
    super.key,
    required this.labels,
    required this.onClear,
  });

  final List<String> labels;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.widthByContext(4)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              labels.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.base(
                12,
                color: AppColors.subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Сбросить',
              style: AppTextStyle.base(12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
