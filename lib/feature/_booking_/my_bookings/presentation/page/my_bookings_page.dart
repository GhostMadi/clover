import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/my_bookings/data/my_bookings_calendar.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/cubit/my_bookings_cubit.dart';
import 'package:clover/feature/_booking_/my_bookings/presentation/widget/my_booking_card.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_month_calendar.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
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

  String _dayCaption(BuildContext context, DateTime day, int count) {
    final today = BookingHostInbox.dayKey(DateTime.now());
    final label = day == today
        ? context.l10n.common_today
        : context.dateFormat.dayMonthLong(day);
    final l10n = context.l10n;
    if (count == 0) return l10n.booking_day_none(label);
    if (count == 1) return l10n.booking_day_one(label);
    if (count >= 2 && count <= 4) return l10n.booking_day_few(label, count);
    return l10n.booking_day_many(label, count);
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
        final accent = bookingServiceAccent(context.colors);

        Widget buildBody() {
          return state.maybeMap(
            error: (s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(14, color: context.colors.subTextColor),
                ),
              ),
            ),
            orElse: () {
              if (items.isEmpty && !isLoading) {
                return Center(
                  child: BookingListEmptyState(
                    title: context.l10n.booking_no_bookings,
                    subtitle: context.l10n.booking_no_bookings_hint,
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          context.l10n.booking_my_intro,
                          style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.4),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: accent.ctaBorder.withValues(alpha: 0.45)),
                          ),
                          child: BookingMonthCalendar(
                            selectedDay: _selectedDay,
                            countsByDay: calendarCounts,
                            onDaySelected: (day) => setState(() => _selectedDay = day),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          _dayCaption(context, _selectedDay, dayItems.length),
                          style: AppTextStyle.base(
                            13,
                            color: accent.icon,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (dayItems.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: BookingListEmptyState(
                            title: context.l10n.booking_no_day_bookings,
                            subtitle: context.l10n.booking_pick_another_day,
                            showCreateButton: false,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        sliver: SliverList.separated(
                          itemCount: dayItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = dayItems[index];
                            return Opacity(
                              opacity: isRefreshing ? 0.75 : 1,
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
                      ),
                    SliverPadding(padding: EdgeInsets.only(bottom: bottomGap)),
                  ],
                ),
              );
            },
          );
        }

        return BookingScreenShell(
          title: context.l10n.booking_my_bookings,
          compactBar: true,
          isLoading: isLoading || isRefreshing,
          body: buildBody(),
        );
      },
    );
  }
}
