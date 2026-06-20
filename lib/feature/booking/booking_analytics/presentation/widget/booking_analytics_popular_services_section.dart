import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/booking/booking_analytics/data/models/booking_analytics_popular_service.dart';
import 'package:flutter/material.dart';

class BookingAnalyticsPopularServicesSection extends StatelessWidget {
  const BookingAnalyticsPopularServicesSection({
    super.key,
    required this.periodLabel,
    required this.totalBookings,
    required this.services,
    this.userLabel,
  });

  final String periodLabel;
  final int totalBookings;
  final List<BookingAnalyticsPopularService> services;
  final String? userLabel;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'За выбранный период записей нет',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(14, color: AppColors.subTextColor),
        ),
      );
    }

    final maxCount = services.map((e) => e.bookingCount).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                periodLabel,
                style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$totalBookings записей',
              style: AppTextStyle.base(13, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Популярные услуги',
          style: AppTextStyle.base(18, color: AppColors.textColor, fontWeight: FontWeight.w800),
        ),
        if (userLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            userLabel!,
            style: AppTextStyle.base(13, color: AppColors.functionalSoftBlueIcon, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 12),
        for (final service in services) ...[
          _PopularServiceRow(service: service, maxCount: maxCount),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PopularServiceRow extends StatelessWidget {
  const _PopularServiceRow({
    required this.service,
    required this.maxCount,
  });

  final BookingAnalyticsPopularService service;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final progress = maxCount == 0 ? 0.0 : service.bookingCount / maxCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoftGreen.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(service.emojiText, style: const TextStyle(fontSize: 22, height: 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${service.bookingCount} записей',
                      style: AppTextStyle.base(12, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
