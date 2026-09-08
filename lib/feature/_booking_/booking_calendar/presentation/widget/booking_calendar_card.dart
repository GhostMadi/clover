import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:flutter/material.dart';

class BookingCalendarCard extends StatelessWidget {
  const BookingCalendarCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final BookingCalendarItem item;
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
    final colors = context.colors;
    final date = item.startsAtDate?.toLocal();
    final dateLabel = date != null ? '${date.day} ${_monthLabels[date.month - 1]}' : '—';
    final timeLabel = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '—';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.serviceEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        16,
                        fontWeight: FontWeight.w700,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.clientName.trim().isEmpty ? 'Клиент' : item.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(14, color: colors.subTextColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$dateLabel · $timeLabel · ${item.statusLabel}',
                      style: AppTextStyle.base(13, color: colors.subTextColor),
                    ),
                  ],
                ),
              ),
              Text(
                item.priceLabel,
                style: AppTextStyle.base(
                  14,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
