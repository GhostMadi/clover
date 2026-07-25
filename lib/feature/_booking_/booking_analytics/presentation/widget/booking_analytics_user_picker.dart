import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/models/booking_analytics_user.dart';
import 'package:flutter/material.dart';

class BookingAnalyticsUserPicker extends StatelessWidget {
  const BookingAnalyticsUserPicker({
    super.key,
    required this.users,
    required this.selectedUserId,
    required this.onChanged,
  });

  final List<BookingAnalyticsUser> users;
  final String? selectedUserId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      const AppSingleSelectOption<String?>(value: null, label: 'Все исполнители'),
      for (final user in users)
        AppSingleSelectOption<String?>(value: user.id, label: user.displayLabel),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Исполнитель',
          style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        AppSingleSelect<String?>(
          hint: 'Все исполнители',
          sheetTitle: 'Фильтр по исполнителю',
          searchHint: 'Поиск по имени',
          options: options,
          value: selectedUserId,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
