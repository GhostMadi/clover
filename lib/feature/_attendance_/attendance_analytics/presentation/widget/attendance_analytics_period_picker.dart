import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clover/core/extension/context.dart';

class AttendanceAnalyticsPeriodPicker extends StatelessWidget {
  const AttendanceAnalyticsPeriodPicker({
    super.key,
    required this.isMonth,
    required this.onWeek,
    required this.onMonth,
    required this.periodLabel,
    required this.onPrevious,
    required this.onNext,
    this.canGoPrevious = true,
    this.canGoNext = false,
  });

  final bool isMonth;
  final VoidCallback onWeek;
  final VoidCallback onMonth;
  final String periodLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _Segment(label: context.l10n.common_week, selected: !isMonth, onTap: onWeek, accent: accent),
                ),
                Expanded(
                  child: _Segment(label: context.l10n.common_month, selected: isMonth, onTap: onMonth, accent: accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _NavButton(icon: AppIcons.chevronLeft.icon, enabled: canGoPrevious, onTap: onPrevious),
            Expanded(
              child: Text(
                periodLabel,
                textAlign: TextAlign.center,
                style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
              ),
            ),
            _NavButton(icon: AppIcons.chevronRight.icon, enabled: canGoNext, onTap: onNext),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 18, color: context.colors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppServiceAccent accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? colors.surface : null,
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.base(
            14,
            color: selected ? accent.icon : colors.subTextColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
