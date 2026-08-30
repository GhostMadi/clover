import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_post_/post/data/models/post_profile_filter_value.dart';
import 'package:flutter/material.dart';

/// Мини-чипы фильтров профиля на карточке поста.
class PostProfileFilterChips extends StatelessWidget {
  const PostProfileFilterChips({
    super.key,
    required this.filters,
  });

  final List<PostProfileFilterValue> filters;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final filter in filters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
            ),
            child: Text(
              filter.label,
              style: AppTextStyle.base(
                11,
                color: AppColors.textColor,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
      ],
    );
  }
}
