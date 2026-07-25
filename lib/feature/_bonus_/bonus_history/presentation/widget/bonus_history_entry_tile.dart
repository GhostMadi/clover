import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';
import 'package:flutter/material.dart';

class BonusHistoryEntryTile extends StatelessWidget {
  const BonusHistoryEntryTile({super.key, required this.entry});

  final BonusHistoryEntry entry;

  static const _monthLabels = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  @override
  Widget build(BuildContext context) {
    final date = entry.occurredAt.toLocal();
    final dateLabel = '${date.day} ${_monthLabels[date.month - 1]}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final amountColor = entry.isCredit ? AppColors.primary : AppColors.destructive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: AppTextStyle.base(15, fontWeight: FontWeight.w700, color: AppColors.textColor),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.subtitle,
                  style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: AppTextStyle.base(12, color: AppColors.subTextColor.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          Text(
            entry.amountLabel,
            style: AppTextStyle.base(18, fontWeight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }
}
