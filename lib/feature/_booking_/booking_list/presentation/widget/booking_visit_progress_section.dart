import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_mini_menu.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/shared/data/booking_status_display.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:flutter/material.dart';

/// Управление визитом host-ом: основной шаг + экстренные действия.
class BookingVisitProgressSection extends StatelessWidget {
  const BookingVisitProgressSection({
    super.key,
    required this.item,
    required this.isLoading,
    required this.onMarkStatus,
    required this.onEmergencyAction,
    this.onRevert,
  });

  final BookingListItem item;
  final bool isLoading;
  final ValueChanged<BookingStatus> onMarkStatus;
  final ValueChanged<BookingHostEmergencyAction> onEmergencyAction;
  final VoidCallback? onRevert;

  @override
  Widget build(BuildContext context) {
    if (BookingStatusDisplay.isTerminal(item.status)) {
      return const SizedBox.shrink();
    }

    final currentStep = BookingStatusDisplay.visitStepIndex(item.status);
    final next = BookingStatusDisplay.nextHostStatus(item.status);
    final canNoShow = BookingStatusDisplay.canHostMarkNoShow(item.status, item.startsAtDate);
    final canRevert = BookingStatusDisplay.canHostRevert(item.status) && onRevert != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Отметки визита',
                  style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
                ),
              ),
              AppMiniMenu<BookingHostEmergencyAction>(
                items: [
                  AppMiniMenuItem(
                    value: BookingHostEmergencyAction.complete,
                    title: 'Завершить визит сейчас',
                    icon: Icons.check_circle_outline_rounded,
                    enabled: !isLoading,
                  ),
                  if (canNoShow)
                    AppMiniMenuItem(
                      value: BookingHostEmergencyAction.noShow,
                      title: 'Клиент не пришёл',
                      icon: Icons.person_off_outlined,
                      enabled: !isLoading,
                    ),
                  AppMiniMenuItem(
                    value: BookingHostEmergencyAction.cancel,
                    title: 'Отменить визит',
                    icon: Icons.block_rounded,
                    titleColor: context.colors.destructive,
                    iconColor: context.colors.destructive,
                    enabled: !isLoading,
                  ),
                ],
                onSelected: onEmergencyAction,
              ),
            ],
          ),
          if (item.isVisitUnmarked) ...[
            const SizedBox(height: 8),
            Text(
              'Время записи прошло. Завершите визит или отметьте «не пришёл» — слот освободится.',
              style: AppTextStyle.base(13, color: context.colors.destructive, height: 1.35),
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
          if (next != null) ...[
            const SizedBox(height: 16),
            AppButton(
              text: BookingStatusDisplay.actionLabel(next),
              height: 48,
              isExpanded: true,
              isLoading: isLoading,
              onTap: isLoading ? null : () => onMarkStatus(next),
            ),
          ],
          if (item.status == BookingStatus.pending) ...[
            const SizedBox(height: 10),
            AppOutlinedButton(
              text: 'Клиент уже пришёл (без подтверждения)',
              height: 48,
              isExpanded: true,
              isLoading: isLoading,
              onTap: isLoading ? null : () => onMarkStatus(BookingStatus.clientArrived),
            ),
          ],
          if (canRevert) ...[
            const SizedBox(height: 10),
            AppOutlinedButton(
              text: BookingStatusDisplay.revertActionLabel(item.status),
              height: 48,
              isExpanded: true,
              isLoading: isLoading,
              onTap: isLoading ? null : onRevert,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.title, required this.isDone, required this.isActive, required this.isLast});

  final String title;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? context.colors.primary
        : isActive
        ? context.colors.functionalSoftBlueIcon
        : context.colors.border;

    return Row(
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
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isDone ? context.colors.primary.withValues(alpha: 0.35) : context.colors.border,
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
                color: isDone || isActive ? context.colors.textColor : context.colors.subTextColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
