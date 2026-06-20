import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_period_banner.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_period_filter_sheet.dart';
import 'package:clover/feature/booking/my_bookings/data/mock/my_bookings_mock_data.dart';
import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/booking/my_bookings/presentation/widget/my_booking_card.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final _allItems = MyBookingsMockData.items;
  late BookingListDateRange _period = BookingListDateRange.recentAndUpcoming();

  List<MyBookingItem> get _filteredItems {
    final items = [
      for (final item in _allItems)
        if (_period.contains(item.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0))) item,
    ];
    items.sort((a, b) {
      final ad = a.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd);
    });
    return items;
  }

  Future<void> _openFilter() async {
    final picked = await BookingListPeriodFilterSheet.show(context, initial: _period);
    if (picked != null && mounted) {
      setState(() => _period = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final periodLabel = 'Период: ${_period.label}';

    return BookingScreenShell(
      title: 'Мои записи',
      compactBar: true,
      showFilter: true,
      onFilterTap: _openFilter,
      body: items.isEmpty
          ? Column(
              children: [
                BookingListPeriodBanner(label: periodLabel),
                Expanded(
                  child: BookingListEmptyState(
                    title: 'Записей за период нет',
                    subtitle: 'Измените фильтр по дате — можно посмотреть прошлые записи',
                    showCreateButton: false,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(0, 8, 0, BookingScreenShell.scrollBottomGap(context)),
              itemCount: items.length + 1,
              separatorBuilder: (context, index) {
                if (index == 0) return const SizedBox.shrink();
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return BookingListPeriodBanner(label: periodLabel);
                }
                final item = items[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MyBookingCard(
                    item: item,
                    onTap: () => context.router.push(MyBookingDetailRoute(item: item)),
                  ),
                );
              },
            ),
    );
  }
}
