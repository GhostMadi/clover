import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:flutter/material.dart';

class FilterSettingsEmptyState extends StatelessWidget {
  const FilterSettingsEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.serviceAccent(kResourcesService);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(AppIcons.tune.icon, size: 32, color: accent.icon),
          ),
          const SizedBox(height: 12),
          Text(
            'Пока нет категорий',
            style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Например: Размер → XS, S, M\nЦвет → Черный, Белый',
            textAlign: TextAlign.center,
            style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.35),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Создать первую категорию',
            isExpanded: true,
            service: kResourcesService,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}
