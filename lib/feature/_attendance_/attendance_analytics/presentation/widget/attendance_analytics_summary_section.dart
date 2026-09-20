import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

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
              child: _MetricTile(label: 'Часы', value: overview.totalLabel),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(label: 'В среднем', value: overview.avgLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$workerCount чел.'
          '${overview.lateDaysTotal > 0 ? ' · ${overview.lateDaysTotal} опозд.' : ''}'
          '${overview.missedDaysTotal > 0 ? ' · ${overview.missedDaysTotal} проп.' : ''}',
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
