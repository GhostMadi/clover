import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

class BookingListEmptyState extends StatelessWidget {
  const BookingListEmptyState({
    super.key,
    this.onCreate,
    this.title = 'Записей пока нет',
    this.subtitle = 'Создайте первую запись — она появится здесь',
    this.showCreateButton = true,
  });

  final VoidCallback? onCreate;
  final String title;
  final String subtitle;
  final bool showCreateButton;

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
                color: accent.soft.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.eventAvailable.icon, size: 36, color: accent.icon.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
            if (showCreateButton && onCreate != null) ...[
              const SizedBox(height: 20),
              BookingPrimaryButton(text: 'Создать запись', isExpanded: true, onTap: onCreate),
            ],
          ],
        ),
      ),
    );
  }
}
