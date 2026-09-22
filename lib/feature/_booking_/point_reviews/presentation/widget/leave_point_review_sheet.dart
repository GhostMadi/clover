import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/_booking_/point_reviews/presentation/widget/point_review_stars.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// Sheet: оставить отзыв (только mock UI).
abstract final class LeavePointReviewSheet {
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      title: 'Оценить визит',
      contentHeight: MediaQuery.sizeOf(context).height * 0.55,
      content: const _LeavePointReviewBody(),
    );
  }
}

class _LeavePointReviewBody extends StatefulWidget {
  const _LeavePointReviewBody();

  @override
  State<_LeavePointReviewBody> createState() => _LeavePointReviewBodyState();
}

class _LeavePointReviewBodyState extends State<_LeavePointReviewBody> {
  int _stars = 0;
  final _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    if (_sent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Спасибо за отзыв',
            style: AppTextStyle.base(18, fontWeight: FontWeight.w600, color: colors.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'В mock он никуда не уходит — только UI. На проде появится на точке и в сводке профиля.',
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
          const Spacer(),
          AppButton(
            text: 'Закрыть',
            isExpanded: true,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Стрижка · Салон на Абая · 21 мар',
          style: AppTextStyle.base(13, color: colors.subTextColor),
        ),
        const SizedBox(height: 20),
        Text(
          'Как прошло?',
          textAlign: TextAlign.center,
          style: AppTextStyle.base(16, fontWeight: FontWeight.w600, color: colors.textColor),
        ),
        const SizedBox(height: 12),
        Center(
          child: PointReviewStars(
            value: _stars,
            size: 32,
            onChanged: (n) => setState(() => _stars = n),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: AppTextStyle.base(15, color: colors.textColor),
            decoration: InputDecoration(
              hintText: 'Расскажите, как прошло (необязательно)',
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
          text: 'Отправить отзыв',
          isExpanded: true,
          onTap: _stars < 1 ? null : () => setState(() => _sent = true),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.infoOutline.icon, size: 14, color: colors.subTextColor),
            const SizedBox(width: 6),
            Text(
              'Mock · без записи на бэк',
              style: AppTextStyle.base(12, color: colors.subTextColor),
            ),
          ],
        ),
      ],
    );
  }
}
