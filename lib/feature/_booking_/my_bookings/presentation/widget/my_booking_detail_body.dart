import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_detail_body.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Деталка записи клиента: шапка + одна практичная карточка фактов.
class MyBookingDetailBody extends StatelessWidget {
  const MyBookingDetailBody({super.key, required this.item});

  final MyBookingItem item;

  String _time(DateTime? date) {
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final start = item.startsAtDate?.toLocal();
    final end = item.endsAtDate?.toLocal();
    final hostLine = [
      item.hostDisplayName,
      if (item.hostUsernameLabel.isNotEmpty) item.hostUsernameLabel,
    ].join(' · ');
    final whenLine = start == null ? '—' : context.dateFormat.fullWeekdayDayMonth(start);
    final timeLine = start == null
        ? '—'
        : context.l10n.booking_time_range_minutes(_time(start), _time(end ?? start), item.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: accent.soft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(item.serviceEmoji, style: AppTextStyle.emoji(24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serviceTitle,
                          style: AppTextStyle.base(
                            18,
                            color: accent.onSoft,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hostLine,
                          style: AppTextStyle.base(
                            13,
                            color: accent.onSoft.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                whenLine,
                style: AppTextStyle.base(
                  14,
                  color: accent.onSoft.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeLine,
                style: AppTextStyle.base(
                  26,
                  color: accent.onSoft,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              BookingListStatusChip(
                status: item.status,
                label: item.statusLabel,
                isUnmarked: item.isVisitUnmarked,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              _FactRow(
                icon: AppIcons.personRounded.icon,
                label: context.l10n.booking_salon_label,
                value: item.hostDisplayName,
              ),
              if (item.executorName != null && item.executorName!.trim().isNotEmpty)
                _FactRow(
                  icon: AppIcons.badge.icon,
                  label: context.l10n.booking_master,
                  value: item.executorName!.trim(),
                ),
              _FactRow(
                icon: AppIcons.payments.icon,
                label: context.l10n.booking_price,
                value: item.priceLabel,
                showDivider: item.notes != null && item.notes!.trim().isNotEmpty,
              ),
              if (item.notes != null && item.notes!.trim().isNotEmpty)
                _FactRow(
                  icon: AppIcons.editOutlined.icon,
                  label: context.l10n.booking_note,
                  value: item.notes!.trim(),
                  multiline: true,
                  showDivider: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiline;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: accent.soft.withValues(alpha: 0.55), shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: accent.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyle.base(
                        15,
                        color: context.colors.textColor,
                        fontWeight: FontWeight.w700,
                        height: multiline ? 1.35 : 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: context.colors.divider.withValues(alpha: 0.8)),
      ],
    );
  }
}
