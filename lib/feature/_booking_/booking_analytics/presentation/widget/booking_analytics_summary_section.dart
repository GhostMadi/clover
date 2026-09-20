import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Сводка периода: выручка, средний чек, статусы.
class BookingAnalyticsSummarySection extends StatelessWidget {
  const BookingAnalyticsSummarySection({
    super.key,
    required this.result,
  });

  final BookingAnalyticsResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Выручка',
                value: _formatMoney(result.revenue),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Средний чек',
                value: result.completedBookings > 0 ? _formatMoney(result.avgCheck) : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${result.totalBookings} записей · ${result.completedBookings} оказано'
          '${result.cancelledBookings > 0 ? ' · ${result.cancelledBookings} отменено' : ''}'
          '${result.pendingBookings > 0 ? ' · ${result.pendingBookings} ждут' : ''}',
          style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  static String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()} ₸';
    }
    return '${value.toStringAsFixed(0)} ₸';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyle.base(20, color: accent.icon, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
