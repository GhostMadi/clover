import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';

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
    final service = attendanceServiceAccent(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AttendanceAnalyticsSectionHeader(
          title: 'Сводка',
          subtitle: 'Общая картина по команде',
        ),
        const SizedBox(height: 14),
        AttendanceAnalyticsCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AttendanceMetricIcon(
                    icon: AppIcons.schedule.icon,
                    tint: service.icon,
                    bg: service.soft,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overview.totalLabel,
                          style: AppTextStyle.base(28, color: colors.textColor, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'отработано командой · $workerCount чел.',
                          style: AppTextStyle.base(13, color: colors.subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CompactMetric(
                      label: 'В среднем',
                      value: overview.avgLabel,
                      icon: AppIcons.groupOutlined.icon,
                      tint: colors.functionalSoftBlueIcon,
                      bg: colors.functionalSoftBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CompactMetric(
                      label: 'Опоздания',
                      value: '${overview.lateDaysTotal}',
                      icon: AppIcons.accessTime.icon,
                      tint: colors.functionalSoftYellowIcon,
                      bg: colors.functionalSoftYellow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CompactMetric(
                      label: 'Пропуски',
                      value: '${overview.missedDaysTotal}',
                      icon: AppIcons.eventBusy.icon,
                      tint: colors.destructive,
                      bg: colors.functionalSoftRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.bg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.pageBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyle.base(16, color: colors.textColor, fontWeight: FontWeight.w800)),
          Text(label, style: AppTextStyle.base(11, color: colors.subTextColor)),
        ],
      ),
    );
  }
}
