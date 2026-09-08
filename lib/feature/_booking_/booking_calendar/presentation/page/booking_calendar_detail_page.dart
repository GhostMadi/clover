import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingCalendarDetailPage extends StatelessWidget {
  const BookingCalendarDetailPage({super.key, required this.item});

  final BookingCalendarItem item;

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
    final when = date == null
        ? '—'
        : '${date.day} ${_monthLabels[date.month - 1]} · '
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final notes = item.notes?.trim();
    final bottomGap = BookingScreenShell.scrollBottomGap(context);

    return BookingScreenShell(
      title: 'Заказ',
      compactBar: true,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
        children: [
          Text(
            '${item.serviceEmoji} ${item.serviceTitle}',
            style: AppTextStyle.base(20, fontWeight: FontWeight.w700, color: colors.textColor),
          ),
          const SizedBox(height: 16),
          _row(context, 'Когда', when),
          _row(context, 'Статус', item.statusLabel),
          _row(
            context,
            'Клиент',
            item.clientName.trim().isEmpty ? '—' : item.clientName,
          ),
          _row(
            context,
            'Аккаунт',
            [
              item.hostDisplayName,
              if (item.hostUsernameLabel.isNotEmpty) item.hostUsernameLabel,
            ].where((e) => e.trim().isNotEmpty).join(' · '),
          ),
          _row(context, 'Цена', item.priceLabel),
          _row(context, 'Длительность', '${item.durationMinutes} мин'),
          if (notes != null && notes.isNotEmpty) _row(context, 'Заметка', notes),
          const SizedBox(height: 12),
          Text(
            'Только просмотр. Статус визита меняет аккаунт, который ведёт запись.',
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
