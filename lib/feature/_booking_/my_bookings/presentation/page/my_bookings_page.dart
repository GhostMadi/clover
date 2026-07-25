import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_period_banner.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_period_filter_sheet.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/cubit/my_bookings_cubit.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_card.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  late final MyBookingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MyBookingsCubit>()..load();
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
    return BlocBuilder<MyBookingsCubit, MyBookingsState>(
      bloc: _cubit,
      builder: (context, state) {
        final period = state.maybeMap(
          loaded: (s) => s.period,
          loading: (s) => s.period,
          error: (s) => s.period,
          orElse: () => BookingListDateRange.recentAndUpcoming(),
        );
        final items = state.maybeMap(loaded: (s) => s.items, orElse: () => const <MyBookingItem>[]);
        final isRefreshing = state.maybeMap(loaded: (s) => s.isRefreshing, orElse: () => false);
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false) && items.isEmpty;
        final periodLabel = 'Период: ${period.label}';

        Widget buildBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (items.isEmpty && !isLoading) {
                return Column(
                  children: [
                    BookingListPeriodBanner(label: periodLabel),
                    const Expanded(
                      child: BookingListEmptyState(
                        title: 'Записей за период нет',
                        subtitle: 'Измените фильтр по дате — можно посмотреть прошлые записи',
                        showCreateButton: false,
                      ),
                    ),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(0, 8, 0, BookingScreenShell.scrollBottomGap(context)),
                  itemCount: items.isEmpty ? 1 : items.length + 1,
                  separatorBuilder: (context, index) {
                    if (index == 0) return const SizedBox.shrink();
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return BookingListPeriodBanner(label: periodLabel);
                    }
                    if (items.isEmpty) {
                      return SizedBox(height: MediaQuery.sizeOf(context).height * 0.35);
                    }
                    final item = items[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MyBookingCard(
                        item: item,
                        onTap: () async {
                          final cancelled = await context.router.push<bool>(
                            MyBookingDetailRoute(item: item),
                          );
                          if (cancelled == true && mounted) {
                            await _cubit.refresh();
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        }

        return BookingScreenShell(
          title: 'Мои записи',
          compactBar: true,
          showFilter: true,
          onFilterTap: () => _openFilter(period),
          isLoading: isLoading || isRefreshing,
          body: buildBody(),
        );
      },
    );
  }
}
