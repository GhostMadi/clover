import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Карточка записи клиента в ленте выбранного дня.
class MyBookingCard extends StatelessWidget {
  const MyBookingCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MyBookingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final date = item.startsAtDate?.toLocal();
    final timeLabel = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '—';
    final durationLabel = item.durationMinutes > 0 ? '${item.durationMinutes} мин' : '';
    final meta = [
      if (item.executorName != null && item.executorName!.trim().isNotEmpty) item.executorName!.trim(),
      if (durationLabel.isNotEmpty) durationLabel,
      if (item.price > 0) item.priceLabel,
    ].join(' · ');

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              _TimeBadge(
                timeLabel: timeLabel,
                isPast: item.isPast,
                soft: accent.soft,
                ink: accent.icon,
              ),
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
                        color: context.colors.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.hostDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        13,
                        color: context.colors.subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(12, color: context.colors.iconMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BookingListStatusChip(
                    status: item.status,
                    label: item.statusLabel,
                    isUnmarked: item.isVisitUnmarked,
                  ),
                  const SizedBox(height: 6),
                  Icon(AppIcons.chevronRight.icon, size: 18, color: context.colors.iconMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({
    required this.timeLabel,
    required this.isPast,
    required this.soft,
    required this.ink,
  });

  final String timeLabel;
  final bool isPast;
  final Color soft;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: isPast ? context.colors.surfaceMuted : soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        timeLabel,
        textAlign: TextAlign.center,
        style: AppTextStyle.base(
          16,
          color: isPast ? context.colors.subTextColor : ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
