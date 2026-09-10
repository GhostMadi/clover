import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_nav_bar/app_tab_reselect_tap_logic.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_chat_/chat/presentation/chat_push_open_bus.dart';
import 'package:clover/feature/_chat_/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:clover/feature/_feed_/events_page/data/events_filter_location_store.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_content_kind.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_pending_sheet.dart';
import 'package:clover/feature/_feed_/events_page/presentation/scope/events_feed_filter_scope.dart';
import 'package:clover/feature/_feed_/events_page/presentation/widget/events_filter_sheet.dart';
import 'package:clover/feature/_feed_/map_page/presentation/scope/map_markers_filter_scope.dart';
import 'package:clover/feature/_feed_/map_page/presentation/widget/map_markers_filter_sheet.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/cubit/notifications_unread_cubit.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_dashboard_more_sheet.dart';
import 'package:clover/feature/dashboard_page/data/models/dashboard_home_mode.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_home_tab_config.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_tab_config.dart';
import 'package:clover/feature/dashboard_page/presentation/cubit/dashboard_home_mode_cubit.dart';
import 'package:clover/feature/dashboard_page/presentation/widget/dashboard_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class AppDashboardPage extends StatefulWidget {
  const AppDashboardPage({super.key});

  @override
  State<AppDashboardPage> createState() => _AppDashboardPageState();
}

class _AppDashboardPageState extends State<AppDashboardPage> with WidgetsBindingObserver {
  late final DashboardHomeModeCubit _homeModeCubit;
  late final AppTabReselectTapLogic _tabReselectLogic;
  late final NotificationsUnreadCubit _notificationsUnreadCubit;
  late final ChatUnreadCubit _chatUnreadCubit;
  late final ChatPushOpenBus _chatPushOpenBus;
  late final AttendanceContextStore _attendanceStore;

  StreamSubscription<ChatPushOpenRequest>? _chatPushSub;

  EventsFilter _eventsFilter = const EventsFilter();
  EventsFilter _mapFilter = const EventsFilter(contentKind: EventsContentKind.eventsOnly);
  bool _ready = false;
  bool _pendingSheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeModeCubit = sl<DashboardHomeModeCubit>();
    _notificationsUnreadCubit = sl<NotificationsUnreadCubit>();
    _chatUnreadCubit = sl<ChatUnreadCubit>();
    _chatPushOpenBus = sl<ChatPushOpenBus>();
    _attendanceStore = sl<AttendanceContextStore>();
    _tabReselectLogic = AppTabReselectTapLogic();
    // Баннер/open-from-push: слушатель до async bootstrap, иначе события теряются.
    _bindChatPushOpen();
    unawaited(_chatUnreadCubit.start());
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_chatPushSub?.cancel());
    _tabReselectLogic.dispose();
    _homeModeCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pendingSheetShown = false;
      _maybeShowAttendancePendingSheet();
      unawaited(_chatUnreadCubit.refresh());
    }
  }

  Future<void> _bootstrap() async {
    final saved = await sl<EventsFilterLocationStore>().read();
    await _homeModeCubit.load();
    unawaited(_notificationsUnreadCubit.refresh());
    if (!mounted) return;

    setState(() {
      _ready = true;
      if (saved.countryCode != null || saved.cityCode != null) {
        _eventsFilter = _eventsFilter.copyWith(countryCode: saved.countryCode, cityCode: saved.cityCode);
        _mapFilter = _mapFilter.copyWith(countryCode: saved.countryCode, cityCode: saved.cityCode);
      }
    });

    // Attendance — сеть; не держим весь дашборд на лоадере.
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid != null && uid.isNotEmpty) {
      unawaited(
        _attendanceStore.hydrate(uid).then((_) {
          if (mounted) _maybeShowAttendancePendingSheet();
        }),
      );
    }
  }

  void _bindChatPushOpen() {
    unawaited(_chatPushSub?.cancel());
    _chatPushSub = _chatPushOpenBus.stream.listen(_onChatPushOpen);

    final pending = _chatPushOpenBus.takePending();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onChatPushOpen(pending);
      });
    }
  }

  void _onChatPushOpen(ChatPushOpenRequest request) {
    if (!mounted) return;
    if (request.autoOpen) {
      unawaited(_openChatFromPush(request));
      return;
    }

    final preview = (request.preview ?? '').trim();
    AppSnackBar.show(
      context,
      title: request.peerUsername ?? 'Чат',
      message: preview.isEmpty ? 'Новое сообщение' : preview,
      kind: AppSnackBarKind.chat,
      placement: AppSnackBarPlacement.top,
      duration: const Duration(seconds: 5),
      onTap: () => unawaited(_openChatFromPush(request)),
    );
  }

  Future<void> _openChatFromPush(ChatPushOpenRequest request) async {
    if (!mounted) return;
    await context.router.push(
      ChatRoute(
        chatId: request.conversationId,
        username: request.peerUsername ?? 'Чат',
        isGroup: request.isGroup,
      ),
    );
    if (!mounted) return;
    unawaited(_chatUnreadCubit.refresh());
  }

  void _maybeShowAttendancePendingSheet() {
    if (_pendingSheetShown || !mounted) return;
    final snap = _attendanceStore.snapshot.value;
    if (snap == null || !snap.isWorker) return;
    if (snap.resolvePendingPunch() == null && !snap.memberships.any((m) => m.needsAck)) return;

    _pendingSheetShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AttendancePendingSheet.showIfNeeded(context, snap);
    });
  }

  Future<void> _openHomeFilter(DashboardHomeMode homeMode) async {
    if (homeMode == DashboardHomeMode.map) {
      final picked = await MapMarkersFilterSheet.show(context, initial: _mapFilter);
      if (picked != null && mounted) {
        setState(() => _mapFilter = picked);
      }
      return;
    }

    final picked = await EventsFilterSheet.show(context, initial: _eventsFilter);
    if (picked != null && mounted) {
      setState(() => _eventsFilter = picked);
    }
  }

  Future<void> _openNotifications() async {
    await context.router.push(const NotificationsRoute());
    if (!mounted) return;
    unawaited(_notificationsUnreadCubit.refresh());
  }

  void _openProfileMore() {
    ProfileDashboardMoreSheet.show(context);
  }

  void _handleTabTap(TabsRouter tabsRouter, int index) {
    _tabReselectLogic.handleTap(
      index: index,
      activeIndex: tabsRouter.activeIndex,
      doubleTapReselectIndices: DashboardHomeTabConfig.doubleTapReselectIndices,
      onSelect: tabsRouter.setActiveIndex,
      onDoubleTapReselect: (_) => unawaited(_homeModeCubit.toggle()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: context.colors.pageBackground,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return BlocProvider.value(
      value: _homeModeCubit,
      child: BlocProvider.value(
        value: _notificationsUnreadCubit,
        child: BlocProvider.value(
          value: _chatUnreadCubit,
          child: AutoTabsRouter(
            routes: DashboardTabConfig.routes,
            builder: (context, child) {
              final tabsRouter = AutoTabsRouter.of(context);
              final activeIndex = tabsRouter.activeIndex;
              final homeMode = context.watch<DashboardHomeModeCubit>().state;

              // Обычный Scaffold + Stack: позиция навбара — наша логика.
              return EventsFeedFilterScope(
                filter: _eventsFilter,
                child: MapMarkersFilterScope(
                  filter: _mapFilter,
                  child: Scaffold(
                    extendBody: true,
                    resizeToAvoidBottomInset: true,
                    backgroundColor: context.colors.pageBackground,
                    body: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: child),
                        BlocBuilder<NotificationsUnreadCubit, int>(
                          builder: (context, notificationsUnread) {
                            return BlocBuilder<ChatUnreadCubit, int>(
                              builder: (context, chatUnread) {
                                return ValueListenableBuilder(
                                  valueListenable: _attendanceStore.snapshot,
                                  builder: (context, attendanceSnap, _) {
                                    final chatBadge = chatUnread > 0 ||
                                        (attendanceSnap?.mockUnreadAttendanceChat ?? false);
                                    return DashboardBottomBar(
                                      currentIndex: activeIndex,
                                      items: DashboardTabConfig.navItemsFor(
                                        homeMode,
                                        showChatBadge: chatBadge,
                                      ),
                                      onTabTap: (index) => _handleTabTap(tabsRouter, index),
                                      onHomeTab: DashboardTabConfig.showHomeTabAccessories(activeIndex),
                                      showHomeTabFilter: DashboardTabConfig.showHomeTabFilter(activeIndex),
                                      showHomeTabNotifications:
                                          DashboardTabConfig.showHomeTabNotifications(activeIndex),
                                      showProfileAccessories:
                                          activeIndex == DashboardTabConfig.profileTabIndex,
                                      showFilterBadge: homeMode == DashboardHomeMode.map
                                          ? _mapFilter.hasSelection
                                          : _eventsFilter.hasSelection,
                                      showNotificationsBadge: notificationsUnread > 0,
                                      onFilterTap: () => unawaited(_openHomeFilter(homeMode)),
                                      onNotificationsTap: () => unawaited(_openNotifications()),
                                      onProfileMoreTap: _openProfileMore,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
