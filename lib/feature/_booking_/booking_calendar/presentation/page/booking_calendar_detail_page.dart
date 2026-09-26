import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingCalendarDetailPage extends StatelessWidget {
  const BookingCalendarDetailPage({super.key, required this.item});

  final BookingCalendarItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = item.startsAtDate?.toLocal();
    final when = date == null
        ? '—'
        : '${context.dateFormat.dayMonth(date)} · '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final notes = item.notes?.trim();
    final bottomGap = BookingScreenShell.scrollBottomGap(context);

    return BookingScreenShell(
      title: context.l10n.booking_order,
      compactBar: true,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
        children: [
          Text(
            '${item.serviceEmoji} ${item.serviceTitle}',
            style: AppTextStyle.base(20, fontWeight: FontWeight.w700, color: colors.textColor),
          ),
          const SizedBox(height: 16),
          _row(context, context.l10n.booking_when_label, when),
          _row(context, context.l10n.booking_status_label, item.statusLabel),
          _row(
            context,
            context.l10n.booking_client,
            item.clientName.trim().isEmpty ? '—' : item.clientName,
          ),
          _row(
            context,
            context.l10n.booking_account,
            [
              item.hostDisplayName,
              if (item.hostUsernameLabel.isNotEmpty) item.hostUsernameLabel,
            ].where((e) => e.trim().isNotEmpty).join(' · '),
          ),
          _row(context, context.l10n.booking_price, item.priceLabel),
          _row(context, context.l10n.booking_duration, context.l10n.booking_minutes_plain(item.durationMinutes)),
          if (notes != null && notes.isNotEmpty) _row(context, context.l10n.booking_note, notes),
          const SizedBox(height: 12),
          Text(
            context.l10n.booking_view_only_status,
            style: AppTextStyle.base(13, color: colors.subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyle.base(12, color: colors.subTextColor)),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: colors.textColor),
          ),
        ],
      ),
    );
  }
}
