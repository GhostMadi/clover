import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/booking/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/booking/booking_list/presentation/cubit/booking_list_cubit.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_card.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_period_banner.dart';
import 'package:clover/feature/booking/booking_list/presentation/widget/booking_list_period_filter_sheet.dart';
import 'package:clover/feature/booking/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key});

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  late final BookingListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingListCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openFilter(BookingListDateRange current) async {
    final picked = await BookingListPeriodFilterSheet.show(context, initial: current);
    if (picked != null && mounted) {
      await _cubit.setPeriod(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingListCubit, BookingListState>(
      bloc: _cubit,
      builder: (context, state) {
        final period = state.maybeMap(
          loaded: (s) => s.period,
          loading: (s) => s.period,
          error: (s) => s.period,
          orElse: () => BookingListDateRange.today(),
        );
        final items = state.maybeMap(loaded: (s) => s.items, orElse: () => const <BookingListItem>[]);
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false);
        final periodLabel = 'Период: ${period.label}';

        return BookingScreenShell(
          title: 'Мои записи',
          showFilter: true,
          onFilterTap: () => _openFilter(period),
          showServices: true,
          showAnalytics: true,
          onServicesTap: () => context.router.push(const BookingCreateRoute()),
          onAnalyticsTap: () => context.router.push(const BookingAnalyticsRoute()),
          isLoading: isLoading,
          body: state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () => items.isEmpty
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
                      final item = items[index - 1];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BookingListCard(
                          item: item,
                          onTap: () async {
                            final updated = await context.router.push<BookingListItem>(
                              BookingListDetailRoute(item: item),
                            );
                            if (updated != null && mounted) {
                              await _cubit.load(period: period);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
