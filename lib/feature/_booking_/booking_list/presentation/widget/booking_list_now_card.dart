import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_action_card.dart';
import 'package:flutter/material.dart';

class BookingListNowCard extends StatelessWidget {
  const BookingListNowCard({
    super.key,
    required this.item,
    this.onOpenProfile,
    this.onOpenDetails,
  });

  final BookingListItem item;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final start = item.startsAtDate;
    final end = item.endsAtDate;
    final timeRange =
        '${BookingListActionCard.timeLabel(start)} – ${BookingListActionCard.timeLabel(end)}';

    return Material(
      color: AppColors.surfaceSoftGreen.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderCardGreen.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Сейчас в кресле',
                style: AppTextStyle.base(13, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                item.clientName.isEmpty ? 'Клиент' : item.clientName,
                style: AppTextStyle.base(22, color: AppColors.textColor, fontWeight: FontWeight.w800),
              ),
              if (item.clientUsernameLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.clientUsernameLabel,
                  style: AppTextStyle.base(14, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${item.serviceEmoji} ${item.serviceTitle}',
                style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                timeRange,
                style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
              ),
              if (item.executorName?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  'Мастер: ${item.executorName}',
                  style: AppTextStyle.base(13, color: AppColors.subTextColor),
                ),
              ],
              if (item.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  item.notes!.trim(),
                  style: AppTextStyle.base(14, color: AppColors.textColor, height: 1.35),
                ),
              ],
              if (onOpenProfile != null) ...[
                const SizedBox(height: 16),
                AppOutlinedButton(
                  text: 'Профиль клиента',
                  height: 48,
                  borderRadius: 14,
                  isExpanded: true,
                  onTap: onOpenProfile,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
