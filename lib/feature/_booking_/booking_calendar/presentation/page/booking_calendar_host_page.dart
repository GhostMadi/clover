import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/booking_calendar_days.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/booking_calendar/presentation/cubit/booking_calendar_bookings_cubit.dart';
import 'package:clover/feature/_booking_/booking_calendar/presentation/widget/booking_calendar_card.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_month_calendar.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingCalendarHostPage extends StatefulWidget {
  const BookingCalendarHostPage({
    super.key,
    required this.hostId,
    this.hostTitle = '',
  });

  final String hostId;
  final String hostTitle;

  @override
  State<BookingCalendarHostPage> createState() => _BookingCalendarHostPageState();
}

class _BookingCalendarHostPageState extends State<BookingCalendarHostPage> {
  late final BookingCalendarBookingsCubit _cubit;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = BookingHostInbox.dayKey(DateTime.now());
    _cubit = sl<BookingCalendarBookingsCubit>()..load(hostId: widget.hostId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.hostTitle.trim().isEmpty ? 'Заказы' : widget.hostTitle;

    return BlocBuilder<BookingCalendarBookingsCubit, BookingCalendarBookingsState>(
      bloc: _cubit,
      builder: (context, state) {
        final items = state.maybeMap(
          loaded: (s) => s.items,
          orElse: () => const <BookingCalendarItem>[],
        );
        final dayItems = BookingCalendarDays.forDay(items, _selectedDay);
        final calendarCounts = BookingCalendarDays.countsByDay(items);
        final isRefreshing = state.maybeMap(loaded: (s) => s.isRefreshing, orElse: () => false);
        final isLoading =
            state.maybeMap(loading: (_) => true, orElse: () => false) && items.isEmpty;
        final bottomGap = BookingScreenShell.scrollBottomGap(context);

        Widget buildBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (items.isEmpty && !isLoading) {
                return const Center(
                  child: BookingListEmptyState(
                    title: 'Заказов пока нет',
                    subtitle: 'Когда к вам запишут, визиты появятся здесь',
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
                          title: 'На этот день заказов нет',
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
                            return BookingCalendarCard(
                              item: item,
                              onTap: () {
                                context.router.push(BookingCalendarDetailRoute(item: item));
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
          title: title,
          compactBar: true,
          isLoading: isLoading || isRefreshing,
          body: buildBody(),
        );
      },
    );
  }
}
