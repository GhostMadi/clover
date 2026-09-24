import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_booking_/point_reviews/data/point_reviews_mock.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Sheet: ответ хозяина на отзыв (mock).
abstract final class ReplyPointReviewSheet {
  static Future<bool> show(
    BuildContext context, {
    required PointReviewMockItem review,
  }) async {
    final hasReply = review.hostReply != null && review.hostReply!.trim().isNotEmpty;
    final result = await AppBottomSheet.show<bool>(
      context: context,
      title: hasReply ? 'Изменить ответ' : 'Ответить',
      contentHeight: MediaQuery.sizeOf(context).height * 0.48,
      content: _ReplyPointReviewBody(review: review),
    );
    return result == true;
  }
}

class _ReplyPointReviewBody extends StatefulWidget {
  const _ReplyPointReviewBody({required this.review});

  final PointReviewMockItem review;

  @override
  State<_ReplyPointReviewBody> createState() => _ReplyPointReviewBodyState();
}

class _ReplyPointReviewBodyState extends State<_ReplyPointReviewBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.review.hostReply ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);
    final review = widget.review;
    final hasReply = review.hostReply != null && review.hostReply!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${review.authorName} · ${review.pointLabel}',
          style: AppTextStyle.base(13, color: colors.subTextColor),
        ),
        const SizedBox(height: 6),
        Text(
          review.text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.base(14, color: colors.textColor),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            autofocus: true,
            textAlignVertical: TextAlignVertical.top,
            style: AppTextStyle.base(15, color: colors.textColor),
            decoration: InputDecoration(
              hintText: 'Ответ от имени точки',
              hintStyle: AppTextStyle.base(15, color: colors.subTextColor),
              filled: true,
              fillColor: colors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.icon),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Сохранить ответ',
          isExpanded: true,
          onTap: () {
            PointReviewsMock.setHostReply(review.id, _controller.text);
            Navigator.of(context).pop(true);
          },
        ),
        if (hasReply) ...[
          const SizedBox(height: 8),
          AppOutlinedButton(
            text: 'Удалить ответ',
            isExpanded: true,
            onTap: () {
              PointReviewsMock.setHostReply(review.id, '');
              Navigator.of(context).pop(true);
            },
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.infoOutline.icon, size: 14, color: colors.subTextColor),
            const SizedBox(width: 6),
            Text(
              'Mock · ответ хозяина',
              style: AppTextStyle.base(12, color: colors.subTextColor),
            ),
          ],
        ),
      ],
    );
  }
}
