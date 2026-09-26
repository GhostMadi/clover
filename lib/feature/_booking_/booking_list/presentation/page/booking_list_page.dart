import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_booking_/booking_list/data/booking_host_inbox.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/cubit/booking_list_cubit.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_archive_body.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_card.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_day_strip.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_empty_state.dart';
import 'package:clover/feature/_booking_/booking_list/presentation/widget/booking_list_now_card.dart';
import 'package:clover/feature/_booking_/booking_points/data/booking_point_title.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_month_calendar.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_screen_shell.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BookingListPage extends StatefulWidget {
  const BookingListPage({super.key, required this.pointId});

  final String pointId;

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  late final BookingListCubit _cubit;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  late String _title;
  var _showSearch = false;

  @override
  void initState() {
    super.initState();
    _title = context.l10n.booking_my_bookings;
    _cubit = sl<BookingListCubit>()..load(pointId: widget.pointId);
    _searchController = TextEditingController();
    _resolveTitle();
  }

  Future<void> _resolveTitle() async {
    final name = await resolveBookingPointNameCached(widget.pointId);
    if (!mounted || name == null) return;
    setState(() => _title = name);
  }

  void _onPointChanged(String nextId) {
    context.router.replace(BookingListRoute(pointId: nextId));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      unawaited(_cubit.setQuery(q.isEmpty ? null : q));
    });
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
      AppSnackBar.show(context, message: context.l10n.booking_client_profile_unavailable, kind: AppSnackBarKind.info);
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
      AppSnackBar.show(context, message: context.l10n.booking_status_update_failed, kind: AppSnackBarKind.error);
      unawaited(_cubit.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

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
        final dayOptions = BookingHostInbox.upcomingDayOptions(items);

        void onCalendarDaySelected(DateTime day) {
          _cubit.setUpcomingDay(day);
          _cubit.setMainTab(BookingHostInboxTab.upcoming.index);
        }

        Future<void> openMonthCalendar() async {
          HapticFeedback.selectionClick();
          final picked = await BookingMonthCalendarSheet.show(
            context,
            selectedDay: upcomingDay,
            countsByDay: calendarCounts,
          );
          if (picked == null || !mounted) return;
          onCalendarDaySelected(picked);
        }

        Widget buildScrollBody() {
          return state.maybeMap(
            error: (s) => Center(child: Text(s.message)),
            orElse: () {
              if (isLoading) {
                return const BookingLoader();
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTab(
                                service: kBookingService,
                                tabs: [
                                  for (final t in BookingHostInboxTab.values) t.shortLabel(context.l10n),
                                ],
                                currentIndex: tabIndex,
                                onTabChanged: _cubit.setMainTab,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _HeaderIconButton(
                              icon: AppIcons.search.icon,
                              selected: _showSearch,
                              accent: accent,
                              onTap: () => setState(() => _showSearch = !_showSearch),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showSearch)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: AppField(
                            controller: _searchController,
                            hintText: context.l10n.booking_search_bookings_hint,
                            prefixIcon: AppIcons.search.icon,
                            textInputAction: TextInputAction.search,
                            service: kBookingService,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),
                    if (tab == BookingHostInboxTab.upcoming) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: BookingListDayStrip(
                                  days: dayOptions,
                                  selectedDay: upcomingDay,
                                  countsByDay: calendarCounts,
                                  onSelected: onCalendarDaySelected,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _HeaderIconButton(
                                  icon: AppIcons.calendarMonth.icon,
                                  accent: accent,
                                  onTap: openMonthCalendar,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            BookingHostInbox.archiveDayLabel(upcomingDay),
                            style: AppTextStyle.base(
                              15,
                              color: colors.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ...switch (tab) {
                      BookingHostInboxTab.inChair => _inChairSlivers(
                        context: context,
                        items: inChair,
                        onOpen: _openItem,
                        onOpenProfile: _openClientProfile,
                      ),
                      BookingHostInboxTab.upcoming => _upcomingSlivers(
                        context: context,
                        items: upcoming,
                        allUpcomingEmpty: upcomingAll.isEmpty,
                        onOpen: _openItem,
                      ),
                      BookingHostInboxTab.archive => [
                        SyncedSliverFillOrList(
                          forgotten: forgotten,
                          history: history,
                          cancelled: cancelled,
                          updatingIds: updatingIds,
                          onMarkCompleted: (item) =>
                              _setStatus(item, BookingStatus.completed, context.l10n.booking_marked_arrived),
                          onMarkNoShow: (item) =>
                              _setStatus(item, BookingStatus.noShow, context.l10n.booking_marked_no_show),
                          onOpenItem: _openItem,
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
          title: _title,
          pointId: widget.pointId,
          onPointChanged: _onPointChanged,
          compactBar: true,
          isLoading: isLoading,
          body: buildScrollBody(),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.accent,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final AppServiceAccent accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.soft : context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: AppTab.defaultHeight,
          height: AppTab.defaultHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent.ctaBorder : context.colors.border.withValues(alpha: 0.65),
            ),
          ),
          child: Icon(icon, size: 22, color: selected ? accent.icon : context.colors.iconMuted),
        ),
      ),
    );
  }
}

/// Обёртка, чтобы архив оставался одним sliver-блоком.
class SyncedSliverFillOrList extends StatelessWidget {
  const SyncedSliverFillOrList({
    super.key,
    required this.forgotten,
    required this.history,
    required this.cancelled,
    required this.updatingIds,
    required this.onMarkCompleted,
    required this.onMarkNoShow,
    required this.onOpenItem,
  });

  final List<BookingListItem> forgotten;
  final List<BookingListItem> history;
  final List<BookingListItem> cancelled;
  final Set<String> updatingIds;
  final ValueChanged<BookingListItem> onMarkCompleted;
  final ValueChanged<BookingListItem> onMarkNoShow;
  final ValueChanged<BookingListItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BookingListArchiveBody(
        forgotten: forgotten,
        history: history,
        cancelled: cancelled,
        updatingIds: updatingIds,
        onMarkCompleted: onMarkCompleted,
        onMarkNoShow: onMarkNoShow,
        onOpenItem: onOpenItem,
      ),
    );
  }
}

List<Widget> _inChairSlivers({
  required BuildContext context,
  required List<BookingListItem> items,
  required ValueChanged<BookingListItem> onOpen,
  required ValueChanged<BookingListItem> onOpenProfile,
}) {
  if (items.isEmpty) {
    return [
      SyncedSliverFillRemaining(
        child: BookingListEmptyState(
          title: context.l10n.booking_now_empty_title,
          subtitle: context.l10n.booking_now_empty_subtitle,
          showCreateButton: false,
        ),
      ),
    ];
  }

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
  required List<BookingListItem> items,
  required bool allUpcomingEmpty,
  required ValueChanged<BookingListItem> onOpen,
}) {
  if (items.isEmpty) {
    return [
      SyncedSliverFillRemaining(
        child: BookingListEmptyState(
          title: allUpcomingEmpty ? context.l10n.booking_no_upcoming : context.l10n.booking_no_day_bookings,
          subtitle: allUpcomingEmpty
              ? context.l10n.booking_upcoming_empty_hint
              : context.l10n.booking_pick_other_day_feed,
          showCreateButton: false,
        ),
      ),
    ];
  }

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return BookingListCard(item: item, onTap: () => onOpen(item), timeFirst: true);
        },
      ),
    ),
  ];
}

class SyncedSliverFillRemaining extends StatelessWidget {
  const SyncedSliverFillRemaining({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(hasScrollBody: false, child: child);
  }
}
