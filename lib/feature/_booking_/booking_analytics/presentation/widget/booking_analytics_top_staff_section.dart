import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:flutter/material.dart';

class BookingAnalyticsTopStaffSection extends StatelessWidget {
  const BookingAnalyticsTopStaffSection({
    super.key,
    required this.staff,
  });

  final List<BookingAnalyticsStaffStat> staff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) return const SizedBox.shrink();

    final maxCount = staff.map((e) => e.bookingCount).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Исполнители',
          style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final member in staff) ...[
          _StaffRow(member: member, maxCount: maxCount),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.member,
    required this.maxCount,
  });

  final BookingAnalyticsStaffStat member;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final progress = maxCount == 0 ? 0.0 : member.bookingCount / maxCount;
    final revenueLabel = member.revenue == member.revenue.roundToDouble()
        ? '${member.revenue.toInt()} ₸'
        : '${member.revenue.toStringAsFixed(0)} ₸';

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
              Expanded(
                child: Text(
                  member.displayName,
                  style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                revenueLabel,
                style: AppTextStyle.base(13, color: context.colors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${member.bookingCount} записей · ${member.completedCount} оказано',
            style: AppTextStyle.base(12, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.colors.surfaceSoft,
              color: context.colors.functionalSoftBlueIcon,
            ),
          ),
        ],
      ),
    );
  }
}
