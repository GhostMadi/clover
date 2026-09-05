import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/cubit/booking_list_cubit.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_archive_body.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_card.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_month_calendar.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_now_card.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
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

  Future<void> _openItem(BookingListItem item) async {
    final updated = await context.router.push<BookingListItem>(BookingListDetailRoute(item: item));
    if (updated != null && mounted) {
      _cubit.patchItem(updated);
      unawaited(_cubit.refresh());
    }
  }

  Future<void> _openClientProfile(BookingListItem item) async {
    final clientId = item.clientId?.trim();
    if (clientId == null || clientId.isEmpty) {
      AppSnackBar.show(context, message: 'Профиль клиента недоступен', kind: AppSnackBarKind.info);
      return;
    }
    await context.router.push(GuestProfileRoute(userId: clientId));
  }

  Future<void> _setStatus(BookingListItem item, BookingStatus status, String successMessage) async {
    final ok = await _cubit.updateStatus(item.id, status);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.show(context, message: successMessage, kind: AppSnackBarKind.success);
    } else {
      AppSnackBar.show(context, message: 'Не удалось обновить статус', kind: AppSnackBarKind.error);
      unawaited(_cubit.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingListCubit, BookingListState>(
      bloc: _cubit,
      builder: (context, state) {
        final loaded = state.mapOrNull(loaded: (s) => s);
        final items = loaded?.items ?? const <BookingListItem>[];
        final tabIndex = loaded?.mainTabIndex ?? BookingHostInboxTab.upcoming.index;
        final upcomingDay = loaded?.upcomingDay ?? BookingHostInbox.dayKey(DateTime.now());
        final updatingIds = loaded?.updatingIds ?? const <String>{};
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false) && items.isEmpty;

        final inChair = BookingHostInbox.inChair(items);
        final upcomingAll = BookingHostInbox.upcoming(items);
        final upcoming = BookingHostInbox.upcoming(items, day: upcomingDay);
        final forgotten = BookingHostInbox.forgotten(items);
        final history = BookingHostInbox.history(items);
        final cancelled = BookingHostInbox.cancelled(items);
        final calendarCounts = BookingHostInbox.overviewCountsByDay(items);

        void onCalendarDaySelected(DateTime day) {
          _cubit.setUpcomingDay(day);
          _cubit.setMainTab(BookingHostInboxTab.upcoming.index);
        }

        Widget buildScrollBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final tab =
                  BookingHostInboxTab.values[tabIndex.clamp(0, BookingHostInboxTab.values.length - 1)];
              final bottomGap = BookingScreenShell.scrollBottomGap(context);

              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: BookingMonthCalendar(
                        selectedDay: upcomingDay,
                        countsByDay: calendarCounts,
                        onDaySelected: onCalendarDaySelected,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: AppTab(
                          scrollable: true,
                          tabs: [
                            BookingHostInboxTab.inChair.label,
                            BookingHostInboxTab.upcoming.label,
                            BookingHostInboxTab.archive.label,
                          ],
                          currentIndex: tabIndex,
                          onTabChanged: _cubit.setMainTab,
                        ),
                      ),
                    ),
                    ...switch (tab) {
                      BookingHostInboxTab.inChair => _inChairSlivers(
                        items: inChair,
                        onOpen: _openItem,
                        onOpenProfile: _openClientProfile,
                      ),
                      BookingHostInboxTab.upcoming => _upcomingSlivers(
                        context: context,
                        selectedDay: upcomingDay,
                        items: upcoming,
                        allUpcomingEmpty: upcomingAll.isEmpty,
                        onOpen: _openItem,
                      ),
                      BookingHostInboxTab.archive => [
                        SliverToBoxAdapter(
                          child: BookingListArchiveBody(
                            forgotten: forgotten,
                            history: history,
                            cancelled: cancelled,
                            updatingIds: updatingIds,
                            onMarkCompleted: (item) => _setStatus(item, BookingStatus.completed, 'Отмечено: был'),
                            onMarkNoShow: (item) => _setStatus(item, BookingStatus.noShow, 'Отмечено: не пришёл'),
                            onOpenItem: _openItem,
                          ),
                        ),
                      ],
                    },
                    SliverPadding(padding: EdgeInsets.only(bottom: bottomGap)),
                  ],
                ),
              );
            },
          );
        }

        return BookingScreenShell(
          title: 'Мои записи',
          showServices: true,
          showAnalytics: true,
          onServicesTap: () => context.router.push(const BookingCreateRoute()),
          onAnalyticsTap: () => context.router.push(const BookingAnalyticsRoute()),
          isLoading: isLoading,
          body: buildScrollBody(),
        );
      },
    );
  }
}

List<Widget> _inChairSlivers({
  required List<BookingListItem> items,
  required ValueChanged<BookingListItem> onOpen,
  required ValueChanged<BookingListItem> onOpenProfile,
}) {
  if (items.isEmpty) {
    return [
      const SliverFillRemaining(
        hasScrollBody: false,
        child: BookingListEmptyState(
          title: 'Сейчас никого нет',
          subtitle: 'Здесь появится клиент, когда начнётся его визит',
          showCreateButton: false,
        ),
      ),
    ];
  }

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return BookingListNowCard(
            item: item,
            onOpenDetails: () => onOpen(item),
            onOpenProfile: item.clientId?.trim().isNotEmpty == true ? () => onOpenProfile(item) : null,
          );
        },
      ),
    ),
  ];
}

List<Widget> _upcomingSlivers({
  required BuildContext context,
  required DateTime selectedDay,
  required List<BookingListItem> items,
  required bool allUpcomingEmpty,
  required ValueChanged<BookingListItem> onOpen,
}) {
  final dayLabel = BookingHostInbox.archiveDayLabel(selectedDay);

  if (items.isEmpty) {
    return [
      if (!allUpcomingEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              dayLabel,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      SliverFillRemaining(
        hasScrollBody: false,
        child: BookingListEmptyState(
          title: allUpcomingEmpty ? 'Предстоящих записей нет' : 'На этот день записей нет',
          subtitle: allUpcomingEmpty
              ? 'Подтверждённые будущие визиты появятся здесь'
              : 'Выберите другой день в календаре',
          showCreateButton: false,
        ),
      ),
    ];
  }

  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          dayLabel,
          style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return BookingListCard(item: item, onTap: () => onOpen(item));
        },
      ),
    ),
  ];
}
