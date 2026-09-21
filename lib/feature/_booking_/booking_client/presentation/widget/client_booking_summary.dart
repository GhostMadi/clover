import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:clover/feature/_booking_/booking_client/data/client_booking_availability.dart';
import 'package:clover/feature/_booking_/booking_client/data/client_booking_bonus_preview.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

class ClientBookingSummary extends StatelessWidget {
  const ClientBookingSummary({
    super.key,
    required this.hostDisplayName,
    required this.executor,
    required this.service,
    required this.startsAt,
    this.clientComment,
    this.useBonuses = true,
    this.bonusBalance = 0,
  });

  final String hostDisplayName;
  final BookingServiceExecutor executor;
  final BookingService service;
  final DateTime startsAt;
  final String? clientComment;
  final bool useBonuses;
  final int bonusBalance;

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const _weekdays = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);
    final end = ClientBookingAvailability.rangeEnd(
      start: startsAt,
      durationMinutes: service.durationMinutes,
      bufferAfterMinutes: service.bufferAfterMinutes,
    );

    final whenLine = '${_weekdays[startsAt.weekday - 1]}, ${startsAt.day} ${_months[startsAt.month - 1]}';
    final timeLine = '${_time(startsAt)}–${_time(end)} · ${service.durationMinutes} мин';

    final expectedSpend = ClientBookingBonusPreview.expectedSpend(
      service: service,
      balance: bonusBalance,
      useBonuses: useBonuses,
    );
    final expectedEarn = ClientBookingBonusPreview.expectedEarn(service);
    final showBonusBlock = ClientBookingBonusPreview.hasBonusFlow(service);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Проверьте перед записью',
            style: AppTextStyle.base(
              12,
              color: accent.onSoft.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${service.emojiText}  ${service.title}',
            style: AppTextStyle.base(17, color: accent.onSoft, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            '$hostDisplayName · ${executor.displayLabel}',
            style: AppTextStyle.base(
              13,
              color: accent.onSoft.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            whenLine,
            style: AppTextStyle.base(
              13,
              color: accent.onSoft.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeLine,
            style: AppTextStyle.base(
              24,
              color: accent.onSoft,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                service.priceLabel,
                style: AppTextStyle.base(16, color: accent.icon, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                'на месте',
                style: AppTextStyle.base(
                  12,
                  color: accent.onSoft.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (showBonusBlock) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Бонусы',
                    style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if (service.bonusPayPercent > 0)
                    Text(
                      useBonuses && expectedSpend > 0
                          ? 'Списать −$expectedSpend ${BonusFormat.bonusWord(expectedSpend)}'
                          : useBonuses
                              ? 'Списать 0 (недостаточно на балансе)'
                              : 'Без списания бонусов',
                      style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600),
                    ),
                  if (expectedEarn > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Начислить +$expectedEarn ${BonusFormat.bonusWord(expectedEarn)}',
                      style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (clientComment != null && clientComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Комментарий: ${clientComment!.trim()}',
              style: AppTextStyle.base(
                13,
                color: accent.onSoft.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _time(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class ClientBookingConflictBanner extends StatelessWidget {
  const ClientBookingConflictBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.functionalSoftRed,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderCardRed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.eventBusy.icon, size: 18, color: colors.functionalSoftRedIcon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.base(13, color: colors.functionalSoftRedIcon, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
