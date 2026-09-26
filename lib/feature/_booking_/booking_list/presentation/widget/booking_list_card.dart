import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

class BookingListCard extends StatelessWidget {
  const BookingListCard({
    super.key,
    required this.item,
    this.onTap,
    this.timeFirst = false,
  });

  final BookingListItem item;
  final VoidCallback? onTap;

  /// В ленте выбранного дня дата не нужна — крупное время слева.
  final bool timeFirst;

  @override
  Widget build(BuildContext context) {
    final date = item.startsAtDate?.toLocal();
    final dateLabel = date != null ? context.dateFormat.dayMonth(date) : '—';
    final timeLabel =
        date != null ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '—';
    final duration = item.durationMinutes;
    final durationLabel = duration > 0 ? context.l10n.booking_minutes_short(duration) : '';

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DateBadge(
                dateLabel: timeFirst ? durationLabel : dateLabel,
                timeLabel: timeLabel,
                timeFirst: timeFirst,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName.trim().isEmpty ? context.l10n.booking_client : item.clientName,
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
                      item.serviceTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(
                        14,
                        color: context.colors.subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
  const _DateBadge({
    required this.dateLabel,
    required this.timeLabel,
    this.timeFirst = false,
  });

  final String dateLabel;
  final String timeLabel;
  final bool timeFirst;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    return Container(
      width: timeFirst ? 64 : 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            timeLabel,
            style: AppTextStyle.base(
              timeFirst ? 17 : 15,
              color: accent.icon,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (dateLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              dateLabel,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.base(
                11,
                color: context.colors.subTextColor,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
