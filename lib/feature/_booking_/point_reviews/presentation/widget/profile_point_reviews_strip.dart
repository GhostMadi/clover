import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/point_reviews/data/point_reviews_mock.dart';
import 'package:clover/feature/_booking_/point_reviews/presentation/widget/point_review_stars.dart';
import 'package:clover/feature/_booking_/point_reviews/presentation/widget/point_reviews_list_sheet.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Полоска отзывов на профиле.
///
/// Сила супер-тега [feedback] ([docs/business/tag-powers.md]):
/// нет тега → блок не рисуем; есть тег → сводка видна всем.
class ProfilePointReviewsStrip extends StatelessWidget {
  const ProfilePointReviewsStrip({
    super.key,
    required this.hasFeedbackTag,
  });

  final bool hasFeedbackTag;

  @override
  Widget build(BuildContext context) {
    if (!PointReviewsMock.enabled || !hasFeedbackTag) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => PointReviewsListSheet.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  PointReviewsMock.average.toStringAsFixed(1),
                  style: AppTextStyle.base(
                    20,
                    fontWeight: FontWeight.w700,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(width: 10),
                PointReviewStars(
                  value: PointReviewsMock.average.round().clamp(1, 5),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${PointReviewsMock.totalCount} отзывов',
                        style: AppTextStyle.base(
                          14,
                          fontWeight: FontWeight.w600,
                          color: colors.textColor,
                        ),
                      ),
                      Text(
                        'По точкам записи · тег feedback',
                        style: AppTextStyle.base(12, color: colors.subTextColor),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight.icon, color: accent.icon, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
