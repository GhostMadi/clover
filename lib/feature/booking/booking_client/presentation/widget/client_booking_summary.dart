import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/booking/booking_client/data/client_booking_availability.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:flutter/material.dart';

class ClientBookingSummary extends StatelessWidget {
  const ClientBookingSummary({
    super.key,
    required this.hostDisplayName,
    required this.executor,
    required this.service,
    required this.startsAt,
  });

  final String hostDisplayName;
  final BookingServiceExecutor executor;
  final BookingService service;
  final DateTime startsAt;

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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.functionalSoftBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCardBlue.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Итого',
            style: AppTextStyle.base(14, color: AppColors.functionalSoftBlueIcon, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            hostDisplayName,
            style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            executor.displayLabel,
            style: AppTextStyle.base(13, color: AppColors.textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${service.emojiText} ${service.title}',
            style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(dateLabel, style: AppTextStyle.base(14, color: AppColors.textColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(timeLabel, style: AppTextStyle.base(13, color: AppColors.subTextColor)),
          const SizedBox(height: 6),
          Text(
            service.priceLabel,
            style: AppTextStyle.base(15, color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_busy_rounded, size: 18, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.base(13, color: const Color(0xFFC62828), fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
