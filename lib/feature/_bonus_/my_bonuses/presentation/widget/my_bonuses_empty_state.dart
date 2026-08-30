import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:flutter/material.dart';

class MyBonusesEmptyState extends StatelessWidget {
  const MyBonusesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.loyalty_outlined, size: 56, color: context.colors.subTextColor.withValues(alpha: 0.45)),
            const SizedBox(height: 16),
            Text(
              'Бонусов пока нет',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(17, fontWeight: FontWeight.w700, color: context.colors.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Здесь появятся салоны и магазины, где вы копите бонусы',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
