import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:flutter/material.dart';

class BookingListActionCard extends StatelessWidget {
  const BookingListActionCard({
    super.key,
    required this.item,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.onTap,
    this.isUpdating = false,
    this.emphasize = false,
  });

  final BookingListItem item;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback? onTap;
  final bool isUpdating;
  final bool emphasize;

  static String timeLabel(DateTime? date) {
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = item.startsAtDate;
    final borderColor = emphasize
        ? context.colors.functionalSoftOrangeIcon.withValues(alpha: 0.55)
        : context.colors.border.withValues(alpha: 0.55);
    final background = emphasize ? context.colors.functionalSoftOrange.withValues(alpha: 0.45) : context.colors.surface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName.isEmpty ? 'Клиент' : item.clientName,
                          style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.serviceEmoji} ${item.serviceTitle}',
                          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
                        ),
                        if (item.executorName?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.executorName!,
                            style: AppTextStyle.base(13, color: context.colors.subTextColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    timeLabel(start),
                    style: AppTextStyle.base(15, color: context.colors.primary, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (item.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  item.notes!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.3),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      text: secondaryLabel,
                      height: 44,
                      borderRadius: 14,
                      isExpanded: true,
                      isLoading: isUpdating,
                      onTap: isUpdating ? null : onSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: primaryLabel,
                      height: 44,
                      borderRadius: 14,
                      isExpanded: true,
                      isLoading: isUpdating,
                      onTap: isUpdating ? null : onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
