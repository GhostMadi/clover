import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/theme/app_palette.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/data/models/attendance_analytics_models.dart';
import 'package:flutter/material.dart';

/// Заголовок секции аналитики.
class AttendanceAnalyticsSectionHeader extends StatelessWidget {
  const AttendanceAnalyticsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyle.base(17, color: colors.textColor, fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTextStyle.base(13, color: colors.subTextColor)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Бейдж статуса дня.
class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({super.key, required this.status, this.compact = false});

  final AttendanceDayStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceStatusAccent(colors, status);
    final surface = attendanceStatusSurface(colors, status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.labelRu,
        style: AppTextStyle.base(compact ? 11 : 12, color: accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String attendanceWorkerInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final s = parts.first;
    return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

/// Акцент аватара / строки работника — чередуем синий, розовый, голубой, оранжевый.
class AttendanceWorkerAccent {
  const AttendanceWorkerAccent({required this.surface, required this.icon});

  final Color surface;
  final Color icon;
}

int attendanceWorkerAccentSeed(String workerId) => workerId.hashCode.abs();

AttendanceWorkerAccent attendanceWorkerAccent(AppPalette colors, int seed) {
  return switch (seed.abs() % 4) {
    0 => AttendanceWorkerAccent(
        surface: colors.functionalSoftBlue,
        icon: colors.functionalSoftBlueIcon,
      ),
    1 => AttendanceWorkerAccent(
        surface: colors.functionalSoftRed,
        icon: colors.functionalSoftRedIcon,
      ),
    2 => AttendanceWorkerAccent(
        surface: colors.infoSoft,
        icon: colors.postShareIcon,
      ),
    _ => AttendanceWorkerAccent(
        surface: colors.functionalSoftYellow,
        icon: colors.functionalSoftYellowIcon,
      ),
  };
}

Color attendanceStatusAccent(AppPalette colors, AttendanceDayStatus status) {
  return switch (status) {
    AttendanceDayStatus.full => colors.functionalSoftBlueIcon,
    AttendanceDayStatus.late => colors.functionalSoftYellowIcon,
    AttendanceDayStatus.partial => colors.postShareIcon,
    AttendanceDayStatus.absent => colors.destructive,
    AttendanceDayStatus.excused => colors.functionalSoftBlueIcon,
    AttendanceDayStatus.off => colors.iconMuted,
  };
}

Color attendanceStatusSurface(AppPalette colors, AttendanceDayStatus status) {
  return switch (status) {
    AttendanceDayStatus.full => colors.infoSoft,
    AttendanceDayStatus.late => colors.functionalSoftYellow,
    AttendanceDayStatus.partial => colors.functionalSoftBlue,
    AttendanceDayStatus.absent => colors.functionalSoftRed.withValues(alpha: 0.45),
    AttendanceDayStatus.excused => colors.infoSoft,
    AttendanceDayStatus.off => colors.surfaceMuted,
  };
}

Color statusBackground(AppPalette colors, AttendanceDayStatus? status, bool selected) {
  if (selected) return colors.functionalSoftBlueIcon;
  return switch (status) {
    AttendanceDayStatus.full => colors.infoSoft,
    AttendanceDayStatus.late => colors.functionalSoftYellow,
    AttendanceDayStatus.partial => colors.functionalSoftBlue,
    AttendanceDayStatus.absent => colors.functionalSoftRed.withValues(alpha: 0.55),
    AttendanceDayStatus.excused => colors.infoSoft,
    AttendanceDayStatus.off || null => colors.surfaceMuted,
  };
}

/// Карточка-обёртка секции.
class AttendanceAnalyticsCard extends StatelessWidget {
  const AttendanceAnalyticsCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadowDark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Иконка метрики в сводке.
class AttendanceMetricIcon extends StatelessWidget {
  const AttendanceMetricIcon({super.key, required this.icon, required this.tint, required this.bg});

  final IconData icon;
  final Color tint;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

IconData attendanceStatusIcon(AttendanceDayStatus status) {
  return switch (status) {
    AttendanceDayStatus.full => AppIcons.checkRounded.icon,
    AttendanceDayStatus.late => AppIcons.accessTime.icon,
    AttendanceDayStatus.partial => AppIcons.infoOutline.icon,
    AttendanceDayStatus.absent => AppIcons.eventBusy.icon,
    AttendanceDayStatus.excused => AppIcons.eventAvailable.icon,
    AttendanceDayStatus.off => AppIcons.eventAvailable.icon,
  };
}
