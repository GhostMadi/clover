import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Компактная сводка периода.
class AttendanceAnalyticsSummarySection extends StatelessWidget {
  const AttendanceAnalyticsSummarySection({
    super.key,
    required this.overview,
    required this.workerCount,
  });

  final AttendanceAnalyticsOverview overview;
  final int workerCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(label: context.l10n.common_hours, value: overview.totalLabel),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricTile(label: context.l10n.attendance_analytics_avg, value: overview.avgLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${context.l10n.attendance_analytics_people_count(workerCount)}'
          '${overview.lateDaysTotal > 0 ? context.l10n.attendance_analytics_late_suffix(overview.lateDaysTotal) : ''}'
          '${overview.missedDaysTotal > 0 ? context.l10n.attendance_analytics_missed_suffix(overview.missedDaysTotal) : ''}',
          style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

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
