import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Сводка периода: выручка, средний чек, статусы.
class BookingAnalyticsSummarySection extends StatelessWidget {
  const BookingAnalyticsSummarySection({
    super.key,
    required this.periodLabel,
    required this.result,
    this.userLabel,
  });

  final String periodLabel;
  final BookingAnalyticsResult result;
  final String? userLabel;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                periodLabel,
                style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${result.totalBookings} записей',
              style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (userLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            userLabel!,
            style: AppTextStyle.base(13, color: accent.icon, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Выручка',
                value: _formatMoney(result.revenue),
                subtitle: 'завершённые визиты',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Средний чек',
                value: result.completedBookings > 0 ? _formatMoney(result.avgCheck) : '—',
                subtitle: '${result.completedBookings} оказано',
              ),
            ),
          ],
        ),
        if (_hasStatusBreakdown) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (result.pendingBookings > 0)
                _StatusChip(label: 'Ожидает', count: result.pendingBookings),
              if (result.confirmedBookings > 0)
                _StatusChip(label: 'Подтверждена', count: result.confirmedBookings),
              if (result.completedBookings > 0)
                _StatusChip(label: 'Оказана', count: result.completedBookings),
              if (result.cancelledBookings > 0)
                _StatusChip(label: 'Отменена', count: result.cancelledBookings),
            ],
          ),
        ],
      ],
    );
  }

  bool get _hasStatusBreakdown =>
      result.pendingBookings > 0 ||
      result.confirmedBookings > 0 ||
      result.completedBookings > 0 ||
      result.cancelledBookings > 0;

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
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyle.base(20, color: context.colors.textColor, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyle.base(11, color: context.colors.subTextColor),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.7)),
      ),
      child: Text(
        '$label · $count',
        style: AppTextStyle.base(12, color: accent.icon, fontWeight: FontWeight.w600),
      ),
    );
  }
}
