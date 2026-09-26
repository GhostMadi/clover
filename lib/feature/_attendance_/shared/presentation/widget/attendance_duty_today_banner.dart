import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Инфо-баннер: кто дежурит сегодня. При [dutyOnlyPunch] — предупреждение о замке.
class AttendanceDutyTodayBanner extends StatelessWidget {
  const AttendanceDutyTodayBanner({
    super.key,
    required this.roster,
    this.selfWorkerId,
    this.displayNames = const {},
    this.dutyOnlyPunch = false,
    this.compact = false,
  });

  final AttendanceDutyRoster roster;
  final String? selfWorkerId;
  final Map<String, String> displayNames;
  final bool dutyOnlyPunch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!roster.isConfigured) return const SizedBox.shrink();

    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final today = DateTime.now();
    final onDutyIds = roster.onDutyFor(today);

    if (onDutyIds.isEmpty) {
      return _DutyBox(
        compact: compact,
        icon: AppIcons.eventAvailable.icon,
        iconColor: colors.subTextColor,
        bg: colors.surfaceMuted,
        border: colors.borderSoft,
        title: context.l10n.attendance_duty_not_today,
        subtitle: dutyOnlyPunch
            ? context.l10n.attendance_duty_punch_unavailable
            : context.l10n.attendance_duty_queue_not_workday,
      );
    }

    final names = onDutyIds
        .map((id) {
          final n = displayNames[id]?.trim();
          if (n != null && n.isNotEmpty) return n;
          return id.length > 8 ? '${id.substring(0, 8)}…' : id;
        })
        .join(', ');
    final iAmOnDuty = selfWorkerId != null && onDutyIds.contains(selfWorkerId);

    return _DutyBox(
      compact: compact,
      icon: AppIcons.eventAvailable.icon,
      iconColor: accent.icon,
      bg: accent.soft.withValues(alpha: 0.85),
      border: accent.icon.withValues(alpha: 0.25),
      title: iAmOnDuty
          ? context.l10n.attendance_duty_you_today
          : context.l10n.attendance_duty_today_named(names),
      subtitle: dutyOnlyPunch
          ? (iAmOnDuty
              ? context.l10n.attendance_duty_mode_only_you
              : context.l10n.attendance_duty_mode_only_others_blocked)
          : (iAmOnDuty
              ? context.l10n.attendance_duty_info_notify
              : context.l10n.attendance_duty_info_anyone),
    );
  }
}

class _DutyBox extends StatelessWidget {
  const _DutyBox({
    required this.compact,
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.border,
    required this.title,
    required this.subtitle,
  });

  final bool compact;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: compact ? 20 : 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.base(
                    compact ? 14 : 15,
                    color: colors.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
