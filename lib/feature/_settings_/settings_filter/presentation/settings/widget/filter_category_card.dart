import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:flutter/material.dart';

class FilterCategoryCard extends StatelessWidget {
  const FilterCategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onDelete,
  });

  final FilterCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${category.values.length}',
                    style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.iconMuted),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in category.values) _FilterValueChip(label: value),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterValueChip extends StatelessWidget {
  const _FilterValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: AppTextStyle.base(13, color: AppColors.textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
