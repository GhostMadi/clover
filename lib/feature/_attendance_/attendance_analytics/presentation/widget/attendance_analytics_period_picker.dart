import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/attendance_analytics/presentation/widget/attendance_analytics_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    return AttendanceAnalyticsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Период', style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _Segment(
                      label: 'Неделя',
                      selected: !isMonth,
                      onTap: onWeek,
                    ),
                  ),
                  Expanded(
                    child: _Segment(
                      label: 'Месяц',
                      selected: isMonth,
                      onTap: onMonth,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _NavButton(
                icon: AppIcons.chevronLeft.icon,
                enabled: canGoPrevious,
                onTap: onPrevious,
              ),
              Expanded(
                child: Text(
                  periodLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
                ),
              ),
              _NavButton(
                icon: AppIcons.chevronRight.icon,
                enabled: canGoNext,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
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
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: context.colors.textColor),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? colors.surface : null,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.base(
            14,
            color: selected ? colors.functionalSoftBlueIcon : colors.subTextColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
