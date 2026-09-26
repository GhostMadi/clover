import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

class BookingAnalyticsTopStaffSection extends StatelessWidget {
  const BookingAnalyticsTopStaffSection({
    super.key,
    required this.staff,
  });

  final List<BookingAnalyticsStaffStat> staff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.booking_masters_label,
          style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < staff.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _StaffRow(member: staff[i]),
        ],
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member});

  final BookingAnalyticsStaffStat member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final revenueLabel = member.revenue == member.revenue.roundToDouble()
        ? '${member.revenue.toInt()} ₸'
        : '${member.revenue.toStringAsFixed(0)} ₸';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.booking_staff_completed(member.bookingCount, member.completedCount),
                  style: AppTextStyle.base(12, color: colors.subTextColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            revenueLabel,
            style: AppTextStyle.base(14, color: accent.icon, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
