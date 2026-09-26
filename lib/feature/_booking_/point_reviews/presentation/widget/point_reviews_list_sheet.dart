import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_booking_/point_reviews/data/point_reviews_mock.dart';
import 'package:clover/feature/_booking_/point_reviews/presentation/widget/leave_point_review_sheet.dart';
import 'package:clover/feature/_booking_/point_reviews/presentation/widget/point_review_stars.dart';
import 'package:clover/feature/_booking_/point_reviews/presentation/widget/reply_point_review_sheet.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:clover/core/extension/context.dart';

/// Список отзывов с фильтром по точке (mock).
abstract final class PointReviewsListSheet {
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      title: context.l10n.booking_reviews_title,
      contentHeight: MediaQuery.sizeOf(context).height * 0.72,
      content: _PointReviewsListBody(hostContext: context),
    );
  }
}

class _PointReviewsListBody extends StatefulWidget {
  const _PointReviewsListBody({required this.hostContext});

  final BuildContext hostContext;

  @override
  State<_PointReviewsListBody> createState() => _PointReviewsListBodyState();
}

class _PointReviewsListBodyState extends State<_PointReviewsListBody> {
  String _pointId = PointReviewsMock.pointAll;

  Future<void> _reply(PointReviewMockItem review) async {
    final changed = await ReplyPointReviewSheet.show(context, review: review);
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final items = PointReviewsMock.reviews(pointId: _pointId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              PointReviewsMock.average.toStringAsFixed(1),
              style: AppTextStyle.base(28, fontWeight: FontWeight.w700, color: colors.textColor),
            ),
            const SizedBox(width: 10),
            PointReviewStars(value: PointReviewsMock.average.round().clamp(1, 5), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.booking_reviews_count(PointReviewsMock.totalCount),
                style: AppTextStyle.base(13, color: colors.subTextColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PointReviewsMock.points.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = PointReviewsMock.points[index];
              final selected = p.id == _pointId;
              return GestureDetector(
                onTap: () => setState(() => _pointId = p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? accent.icon.withValues(alpha: 0.14) : colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? accent.icon : colors.borderSoft,
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: AppTextStyle.base(
                      13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? accent.icon : colors.textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 24, color: colors.divider),
            itemBuilder: (context, index) {
              final r = items[index];
              final reply = r.hostReply?.trim();
              final hasReply = reply != null && reply.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.authorName,
                          style: AppTextStyle.base(15, fontWeight: FontWeight.w600, color: colors.textColor),
                        ),
                      ),
                      Text(
                        r.dateLabel,
                        style: AppTextStyle.base(12, color: colors.subTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.pointLabel,
                    style: AppTextStyle.base(12, color: colors.subTextColor),
                  ),
                  const SizedBox(height: 6),
                  PointReviewStars(value: r.stars, size: 14),
                  const SizedBox(height: 8),
                  Text(
                    r.text,
                    style: AppTextStyle.base(14, color: colors.textColor),
                  ),
                  if (hasReply) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(AppIcons.replyOutlined.icon, size: 14, color: accent.icon),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.booking_point_reply_label,
                                style: AppTextStyle.base(
                                  12,
                                  fontWeight: FontWeight.w600,
                                  color: accent.icon,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reply,
                            style: AppTextStyle.base(14, color: colors.textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppOutlinedButton(
                      text: hasReply ? context.l10n.booking_edit_reply : context.l10n.booking_reply_action,
                      onTap: () => _reply(r),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          text: context.l10n.booking_demo_leave_review,
          isExpanded: true,
          onTap: () {
            final host = widget.hostContext;
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (host.mounted) {
                LeavePointReviewSheet.show(host);
              }
            });
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.infoOutline.icon, size: 14, color: colors.subTextColor),
            const SizedBox(width: 6),
            Text(
              'Mock · PointReviewsMock.enabled',
              style: AppTextStyle.base(12, color: colors.subTextColor),
            ),
          ],
        ),
      ],
    );
  }
}
