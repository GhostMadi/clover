import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/cubit/booking_list_cubit.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_action_card.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_archive_body.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_card.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_day_strip.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_now_card.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_period_filter_sheet.dart';
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

  Future<void> _openFilter(BookingListDateRange current) async {
    final picked = await BookingListPeriodFilterSheet.show(context, initial: current);
    if (picked != null && mounted) {
      await _cubit.setPeriod(picked);
    }
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
        final period = state.maybeMap(
          loaded: (s) => s.period,
          loading: (s) => s.period,
          error: (s) => s.period,
          orElse: () => BookingListDateRange.thisWeek(),
        );
        final loaded = state.mapOrNull(loaded: (s) => s);
        final items = loaded?.items ?? const <BookingListItem>[];
        final tabIndex = loaded?.mainTabIndex ?? 0;
        final upcomingDay = loaded?.upcomingDay ?? BookingHostInbox.dayKey(DateTime.now());
        final updatingIds = loaded?.updatingIds ?? const <String>{};
        final isLoading = state.maybeMap(loading: (_) => true, orElse: () => false) && items.isEmpty;

        final pending = BookingHostInbox.pending(items);
        final inChair = BookingHostInbox.inChair(items);
        final upcomingAll = BookingHostInbox.upcoming(items);
        final upcoming = BookingHostInbox.upcoming(items, day: upcomingDay);
        final forgotten = BookingHostInbox.forgotten(items);
        final history = BookingHostInbox.history(items);
        final cancelled = BookingHostInbox.cancelled(items);
        final dayOptions = BookingHostInbox.upcomingDayOptions(items);

        Widget buildTabBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final tab =
                  BookingHostInboxTab.values[tabIndex.clamp(0, BookingHostInboxTab.values.length - 1)];
              return switch (tab) {
                BookingHostInboxTab.pending => _PendingTab(
                  items: pending,
                  updatingIds: updatingIds,
                  bottomGap: BookingScreenShell.scrollBottomGap(context),
                  onRefresh: _cubit.refresh,
                  onOpen: _openItem,
                  onAccept: (item) => _setStatus(item, BookingStatus.confirmed, 'Заявка принята'),
                  onReject: (item) => _setStatus(item, BookingStatus.cancelled, 'Заявка отклонена'),
                ),
                BookingHostInboxTab.inChair => _InChairTab(
                  items: inChair,
                  bottomGap: BookingScreenShell.scrollBottomGap(context),
                  onRefresh: _cubit.refresh,
                  onOpen: _openItem,
                  onOpenProfile: _openClientProfile,
                ),
                BookingHostInboxTab.upcoming => _UpcomingTab(
                  dayOptions: dayOptions,
                  selectedDay: upcomingDay,
                  items: upcoming,
                  allUpcomingEmpty: upcomingAll.isEmpty,
                  bottomGap: BookingScreenShell.scrollBottomGap(context),
                  onRefresh: _cubit.refresh,
                  onSelectDay: _cubit.setUpcomingDay,
                  onOpen: _openItem,
                ),
                BookingHostInboxTab.archive => RefreshIndicator(
                  onRefresh: _cubit.refresh,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: BookingScreenShell.scrollBottomGap(context)),
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
                ),
              };
            },
          );
        }

        return BookingScreenShell(
          title: 'Мои записи',
          showFilter: true,
          onFilterTap: () => _openFilter(period),
          showServices: true,
          showAnalytics: true,
          onServicesTap: () => context.router.push(const BookingCreateRoute()),
          onAnalyticsTap: () => context.router.push(const BookingAnalyticsRoute()),
          isLoading: isLoading,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: AppTab(
                  scrollable: true,
                  tabs: [
                    pending.isEmpty
                        ? BookingHostInboxTab.pending.label
                        : '${BookingHostInboxTab.pending.label} · ${pending.length}',
                    BookingHostInboxTab.inChair.label,
                    BookingHostInboxTab.upcoming.label,
                    BookingHostInboxTab.archive.label,
                  ],
                  currentIndex: tabIndex,
                  onTabChanged: _cubit.setMainTab,
                ),
              ),
              Expanded(child: buildTabBody()),
            ],
          ),
        );
      },
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab({
    required this.items,
    required this.updatingIds,
    required this.bottomGap,
    required this.onRefresh,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
  });

  final List<BookingListItem> items;
  final Set<String> updatingIds;
  final double bottomGap;
  final Future<void> Function() onRefresh;
  final ValueChanged<BookingListItem> onOpen;
  final ValueChanged<BookingListItem> onAccept;
  final ValueChanged<BookingListItem> onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            const BookingListEmptyState(
              title: 'Новых заявок нет',
              subtitle: 'Когда клиент запишется, заявка появится здесь',
              showCreateButton: false,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return BookingListActionCard(
            item: item,
            primaryLabel: 'Принять',
            secondaryLabel: 'Отклонить',
            isUpdating: updatingIds.contains(item.id),
            onPrimary: () => onAccept(item),
            onSecondary: () => onReject(item),
            onTap: () => onOpen(item),
          );
        },
      ),
    );
  }
}

class _InChairTab extends StatelessWidget {
  const _InChairTab({
    required this.items,
    required this.bottomGap,
    required this.onRefresh,
    required this.onOpen,
    required this.onOpenProfile,
  });

  final List<BookingListItem> items;
  final double bottomGap;
  final Future<void> Function() onRefresh;
  final ValueChanged<BookingListItem> onOpen;
  final ValueChanged<BookingListItem> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            const BookingListEmptyState(
              title: 'Сейчас никого нет',
              subtitle: 'Здесь появится клиент, когда начнётся его визит',
              showCreateButton: false,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomGap),
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
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.dayOptions,
    required this.selectedDay,
    required this.items,
    required this.allUpcomingEmpty,
    required this.bottomGap,
    required this.onRefresh,
    required this.onSelectDay,
    required this.onOpen,
  });

  final List<DateTime> dayOptions;
  final DateTime selectedDay;
  final List<BookingListItem> items;
  final bool allUpcomingEmpty;
  final double bottomGap;
  final Future<void> Function() onRefresh;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<BookingListItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!allUpcomingEmpty) ...[
          BookingListDayStrip(days: dayOptions, selectedDay: selectedDay, onSelected: onSelectDay),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
                      BookingListEmptyState(
                        title: allUpcomingEmpty ? 'Предстоящих записей нет' : 'На этот день записей нет',
                        subtitle: allUpcomingEmpty
                            ? 'Подтверждённые будущие визиты появятся здесь'
                            : 'Выберите другой день в ленте сверху',
                        showCreateButton: false,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottomGap),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return BookingListCard(item: item, onTap: () => onOpen(item));
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
