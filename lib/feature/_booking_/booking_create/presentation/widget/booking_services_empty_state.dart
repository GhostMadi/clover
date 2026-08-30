import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class BookingServicesEmptyState extends StatelessWidget {
  const BookingServicesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: context.colors.surfaceSoftGreen.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.content_cut_outlined, size: 34, color: context.colors.primary.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 16),
            Text(
              'Услуг пока нет',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(18, color: context.colors.textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + рядом с «Назад», чтобы добавить первую услугу — например, «Стрижка мужская»',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
