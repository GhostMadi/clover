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

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Услуги',
          style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < services.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _PopularServiceRow(service: services[i]),
        ],
      ],
    );
  }
}

class _PopularServiceRow extends StatelessWidget {
  const _PopularServiceRow({required this.service});

  final BookingAnalyticsPopularService service;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Text(service.emojiText, style: AppTextStyle.emoji(22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${service.bookingCount}',
            style: AppTextStyle.base(15, color: accent.icon, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
