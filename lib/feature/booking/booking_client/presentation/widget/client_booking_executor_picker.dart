import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:flutter/material.dart';

class ClientBookingExecutorPicker extends StatelessWidget {
  const ClientBookingExecutorPicker({
    super.key,
    required this.executors,
    required this.selectedId,
    required this.onSelected,
  });

  final List<BookingServiceExecutor> executors;
  final String? selectedId;
  final ValueChanged<BookingServiceExecutor> onSelected;

  @override
  Widget build(BuildContext context) {
    if (executors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Исполнитель',
          style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (final executor in executors) ...[
          _ExecutorTile(
            executor: executor,
            selected: executor.id == selectedId,
            onTap: () => onSelected(executor),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ExecutorTile extends StatelessWidget {
  const _ExecutorTile({
    required this.executor,
    required this.selected,
    required this.onTap,
  });

  final BookingServiceExecutor executor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.functionalSoftBlue : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.functionalSoftBlueIcon : AppColors.border.withValues(alpha: 0.55),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceSoftGreen.withValues(alpha: 0.6),
                child: Text(
                  executor.displayName.characters.first,
                  style: AppTextStyle.base(14, color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  executor.displayLabel,
                  style: AppTextStyle.base(14, color: AppColors.textColor, fontWeight: FontWeight.w600),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 20, color: AppColors.functionalSoftBlueIcon),
            ],
          ),
        ),
      ),
    );
  }
}
