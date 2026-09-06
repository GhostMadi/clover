import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/models/booking_analytics_popular_service.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

class BookingAnalyticsPopularServicesSection extends StatelessWidget {
  const BookingAnalyticsPopularServicesSection({
    super.key,
    required this.services,
  });

  final List<BookingAnalyticsPopularService> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    final maxCount = services.map((e) => e.bookingCount).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Популярные услуги',
          style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w800),
        ),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
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
                  color: context.colors.surfaceSoftGreen.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(service.emojiText, style: AppTextStyle.emoji(22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${service.bookingCount} записей',
                      style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
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
              backgroundColor: context.colors.surfaceSoft,
              color: bookingServiceAccent(context.colors).icon,
            ),
          ),
        ],
      ),
    );
  }
}
