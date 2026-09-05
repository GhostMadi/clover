import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/my_bookings/data/my_bookings_calendar.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/cubit/my_bookings_cubit.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_card.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_month_calendar.dart';
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
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = BookingHostInbox.dayKey(DateTime.now());
    _cubit = sl<MyBookingsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBookingsCubit, MyBookingsState>(
      bloc: _cubit,
      builder: (context, state) {
        final items = state.maybeMap(loaded: (s) => s.items, orElse: () => const <MyBookingItem>[]);
        final dayItems = MyBookingsCalendar.forDay(items, _selectedDay);
        final calendarCounts = MyBookingsCalendar.countsByDay(items);
        final isRefreshing = state.maybeMap(loaded: (s) => s.isRefreshing, orElse: () => false);
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false) && items.isEmpty;
        final bottomGap = BookingScreenShell.scrollBottomGap(context);

        Widget buildBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (items.isEmpty && !isLoading) {
                return const Center(
                  child: BookingListEmptyState(
                    title: 'Записей пока нет',
                    subtitle: 'Когда запишетесь к мастеру, записи появятся здесь',
                    showCreateButton: false,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: BookingMonthCalendar(
                        selectedDay: _selectedDay,
                        countsByDay: calendarCounts,
                        onDaySelected: (day) => setState(() => _selectedDay = day),
                      ),
                    ),
                    if (dayItems.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: BookingListEmptyState(
                          title: 'На этот день записей нет',
                          subtitle: 'Выберите другой день в календаре',
                          showCreateButton: false,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        sliver: SliverList.separated(
                          itemCount: dayItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = dayItems[index];
                            return MyBookingCard(
                              item: item,
                              onTap: () async {
                                final cancelled = await context.router.push<bool>(
                                  MyBookingDetailRoute(item: item),
                                );
                                if (cancelled == true && mounted) {
                                  await _cubit.refresh();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    SliverPadding(padding: EdgeInsets.only(bottom: bottomGap)),
                  ],
                ),
              );
            },
          );
        }

        return BookingScreenShell(
          title: 'Мои записи',
          compactBar: true,
          isLoading: isLoading || isRefreshing,
          body: buildBody(),
        );
      },
    );
  }
}
