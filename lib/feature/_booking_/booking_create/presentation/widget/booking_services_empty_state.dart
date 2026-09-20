import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

class BookingServicesEmptyState extends StatelessWidget {
  const BookingServicesEmptyState({
    super.key,
    this.onCreate,
  });

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final accent = bookingServiceAccent(context.colors);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.contentCut.icon, size: 34, color: accent.icon),
            ),
            const SizedBox(height: 16),
            Text(
              'Услуг пока нет',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте первую — название, длительность и цену',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 20),
              BookingPrimaryButton(text: 'Добавить услугу', isExpanded: true, onTap: onCreate),
            ],
          ],
        ),
      ),
    );
  }
}
