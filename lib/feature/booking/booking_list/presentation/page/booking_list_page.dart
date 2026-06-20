import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/booking/booking_list/data/mock/booking_list_mock_data.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_card.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_period_banner.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_period_filter_sheet.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final _allItems = BookingListMockData.items;
  late BookingListDateRange _period = BookingListDateRange.today();

  List<BookingListItem> get _filteredItems {
    return [
      for (final item in _allItems)
        if (_period.contains(item.startsAtDate ?? DateTime.fromMillisecondsSinceEpoch(0))) item,
    ];
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
      showFilter: true,
      onFilterTap: _openFilter,
      showServices: true,
      showAnalytics: true,
      onServicesTap: () => context.router.push(const BookingCreateRoute()),
      onAnalyticsTap: () => context.router.push(const BookingAnalyticsRoute()),
      body: items.isEmpty
          ? Column(
              children: [
                BookingListPeriodBanner(label: periodLabel),
                Expanded(
                  child: BookingListEmptyState(
                    title: 'Записей за период нет',
                    subtitle: 'Измените фильтр по дате или выберите другой период',
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BookingListCard(
                    item: items[index - 1],
                    onTap: () => context.router.push(
                      BookingListDetailRoute(item: items[index - 1]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
