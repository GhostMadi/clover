import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/shared/data/booking_status_display.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';
import 'package:flutter/material.dart';

/// Ручная фиксация этапов визита host-ом.
class BookingVisitProgressSection extends StatelessWidget {
  const BookingVisitProgressSection({
    super.key,
    required this.item,
    required this.isLoading,
    required this.onMarkStatus,
  });

  final BookingListItem item;
  final bool isLoading;
  final ValueChanged<BookingStatus> onMarkStatus;

  @override
  Widget build(BuildContext context) {
    if (item.status == BookingStatus.cancelled) {
      return const SizedBox.shrink();
    }

    final currentStep = BookingStatusDisplay.visitStepIndex(item.status);
    final next = BookingStatusDisplay.nextHostStatus(item.status);
    final readOnly = item.status == BookingStatus.completed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Отметки визита',
            style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w700),
          ),
          if (item.isVisitUnmarked) ...[
            const SizedBox(height: 8),
            Text(
              'Время записи прошло, но этапы не отмечены. Отметьте фактический итог вручную.',
              style: AppTextStyle.base(13, color: AppColors.destructive, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < BookingStatusDisplay.visitSteps.length; i++)
            _StepRow(
              title: BookingStatusDisplay.visitSteps[i],
              isDone: i == 0 || currentStep >= i,
              isActive: next != null && i == currentStep + 1,
              isLast: i == BookingStatusDisplay.visitSteps.length - 1,
            ),
          if (next != null && !readOnly) ...[
            const SizedBox(height: 16),
            AppButton(
              text: BookingStatusDisplay.actionLabel(next),
              height: 48,
              isExpanded: true,
              isLoading: isLoading,
              onTap: isLoading ? null : () => onMarkStatus(next),
            ),
          ],
          if (item.status == BookingStatus.pending && !readOnly) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: isLoading ? null : () => onMarkStatus(BookingStatus.clientArrived),
              child: Text(
                'Клиент уже пришёл (без подтверждения)',
                style: AppTextStyle.base(13, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.title,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  final String title;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? AppColors.primary
        : isActive
        ? AppColors.functionalSoftBlueIcon
        : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isDone ? dotColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Text(
                title,
                style: AppTextStyle.base(
                  14,
                  color: isDone || isActive ? AppColors.textColor : AppColors.subTextColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
