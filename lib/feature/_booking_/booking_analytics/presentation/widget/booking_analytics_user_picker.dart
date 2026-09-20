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
    if (users.length < 2) return const SizedBox.shrink();

    final options = [
      const AppSingleSelectOption<String?>(value: null, label: 'Все'),
      for (final user in users)
        AppSingleSelectOption<String?>(value: user.id, label: user.displayLabel),
    ];

    return AppSingleSelect<String?>(
      hint: 'Все мастера',
      sheetTitle: 'Мастер',
      searchHint: 'Поиск',
      options: options,
      value: selectedUserId,
      onChanged: onChanged,
    );
  }
}
