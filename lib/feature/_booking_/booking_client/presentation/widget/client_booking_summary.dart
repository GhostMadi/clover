import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/shared/data/bonus_format.dart';
import 'package:clover/feature/_booking_/booking_client/data/client_booking_availability.dart';
import 'package:clover/feature/_booking_/booking_client/data/client_booking_bonus_preview.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
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

  @override
  Widget build(BuildContext context) {
    final end = ClientBookingAvailability.rangeEnd(
      start: startsAt,
      durationMinutes: service.durationMinutes,
      bufferAfterMinutes: service.bufferAfterMinutes,
    );

    final dateLabel = '${startsAt.day} ${_months[startsAt.month - 1]} ${startsAt.year}';
    final timeLabel =
        '${_time(startsAt)} — ${_time(end)} · ${service.durationMinutes} мин';

    final expectedSpend = ClientBookingBonusPreview.expectedSpend(
      service: service,
      balance: bonusBalance,
      useBonuses: useBonuses,
    );
    final expectedEarn = ClientBookingBonusPreview.expectedEarn(service);
    final showBonusBlock = ClientBookingBonusPreview.hasBonusFlow(service);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.functionalSoftBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderCardBlue.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Итого',
            style: AppTextStyle.base(14, color: context.colors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            hostDisplayName,
            style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            executor.displayLabel,
            style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${service.emojiText} ${service.title}',
            style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(dateLabel, style: AppTextStyle.base(14, color: context.colors.textColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(timeLabel, style: AppTextStyle.base(13, color: context.colors.subTextColor)),
          const SizedBox(height: 6),
          Text(
            service.priceLabel,
            style: AppTextStyle.base(15, color: context.colors.primary, fontWeight: FontWeight.w800),
          ),
          if (showBonusBlock) ...[
            const SizedBox(height: 10),
            Text(
              'Бонусы после визита',
              style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            if (service.bonusPayPercent > 0) ...[
              Text(
                useBonuses && expectedSpend > 0
                    ? 'Списать: −$expectedSpend ${BonusFormat.bonusWord(expectedSpend)}'
                    : useBonuses
                        ? 'Списать: 0 ${BonusFormat.bonusWord(0)} (недостаточно на балансе)'
                        : 'Списать: не используем',
                style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600),
              ),
            ],
            if (expectedEarn > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Начислить: +$expectedEarn ${BonusFormat.bonusWord(expectedEarn)}',
                style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Деньги за услугу оплачиваются на месте — приложение ведёт только бонусный счёт.',
              style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w500, height: 1.35),
            ),
          ],
          if (clientComment != null && clientComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Комментарий',
              style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              clientComment!.trim(),
              style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600, height: 1.35),
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
