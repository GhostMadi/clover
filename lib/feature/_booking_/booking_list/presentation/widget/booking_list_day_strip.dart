import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingListDayStrip extends StatelessWidget {
  const BookingListDayStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final selectedKey = BookingHostInbox.dayKey(selectedDay);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final key = BookingHostInbox.dayKey(day);
          final selected = key == selectedKey;
          final label = BookingHostInbox.dayStripLabel(day);
          final dayNumber = '${key.day}';

          return Material(
            color: selected ? AppColors.primary : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                if (selected) return;
                HapticFeedback.selectionClick();
                onSelected(key);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyle.base(
                        12,
                        color: selected ? AppColors.white : AppColors.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      dayNumber,
                      style: AppTextStyle.base(
                        11,
                        color: selected ? AppColors.white.withValues(alpha: 0.85) : AppColors.subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
