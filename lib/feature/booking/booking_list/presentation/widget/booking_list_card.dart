import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:flutter/material.dart';

class BookingListCard extends StatelessWidget {
  const BookingListCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final BookingListItem item;
  final VoidCallback? onTap;

  static const _monthLabels = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  @override
  Widget build(BuildContext context) {
    final date = item.startsAtDate?.toLocal();
    final dateLabel = date != null ? '${date.day} ${_monthLabels[date.month - 1]}' : '—';
    final timeLabel = date != null ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '—';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBadge(dateLabel: dateLabel, timeLabel: timeLabel),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceTitle,
                      style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.clientName,
                      style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              BookingListStatusChip(
                status: item.status,
                label: item.statusLabel,
                isUnmarked: item.isVisitUnmarked,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.dateLabel, required this.timeLabel});

  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCardGreen.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Text(
            timeLabel,
            style: AppTextStyle.base(15, color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.base(11, color: AppColors.subTextColor, fontWeight: FontWeight.w600, height: 1.15),
          ),
        ],
      ),
    );
  }
}
