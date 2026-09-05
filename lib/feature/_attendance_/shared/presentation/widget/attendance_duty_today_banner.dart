import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_workers_mock.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_duty_roster.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Инфо-баннер: кто дежурит сегодня. Не блокирует punch.
class AttendanceDutyTodayBanner extends StatelessWidget {
  const AttendanceDutyTodayBanner({
    super.key,
    required this.roster,
    this.selfWorkerId,
    this.compact = false,
  });

  final AttendanceDutyRoster roster;
  final String? selfWorkerId;
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
        title: 'Сегодня не день дежурства',
        subtitle: 'Очередь есть, но сегодня не рабочий день по настройке.',
      );
    }

    final names = onDutyIds
        .map((id) => AttendanceWorkersMock.byId(id)?.displayName ?? id)
        .join(', ');
    final iAmOnDuty = selfWorkerId != null && onDutyIds.contains(selfWorkerId);

    return _DutyBox(
      compact: compact,
      icon: AppIcons.eventAvailable.icon,
      iconColor: accent.icon,
      bg: accent.soft.withValues(alpha: 0.85),
      border: accent.icon.withValues(alpha: 0.25),
      title: iAmOnDuty ? 'Сегодня дежурите вы' : 'Сегодня дежурит: $names',
      subtitle: iAmOnDuty
          ? 'Инфо + уведомление команде. Отметка доступна как обычно — дежурство не замок.'
          : 'Инфо для команды (уведомление уходит). Отметиться может любой принятый работник.',
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
