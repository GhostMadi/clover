import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_nav_bar/app_tab_reselect_tap_logic.dart';
import 'package:clover/feature/_feed_/events_page/data/events_filter_location_store.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/events_page/presentation/scope/events_feed_filter_scope.dart';
import 'package:clover/feature/_feed_/events_page/presentation/widget/events_filter_sheet.dart';
import 'package:clover/feature/_feed_/map_page/presentation/scope/map_markers_filter_scope.dart';
import 'package:clover/feature/_feed_/map_page/presentation/widget/map_markers_filter_sheet.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_dashboard_more_sheet.dart';
import 'package:clover/feature/dashboard_page/data/models/dashboard_home_mode.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_home_tab_config.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_tab_config.dart';
import 'package:clover/feature/dashboard_page/presentation/cubit/dashboard_home_mode_cubit.dart';
import 'package:clover/feature/dashboard_page/presentation/widget/dashboard_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class AppDashboardPage extends StatefulWidget {
  const AppDashboardPage({super.key});

  @override
  State<AppDashboardPage> createState() => _AppDashboardPageState();
}

class _AppDashboardPageState extends State<AppDashboardPage> {
  late final DashboardHomeModeCubit _homeModeCubit;
  late final AppTabReselectTapLogic _tabReselectLogic;

  EventsFilter _eventsFilter = const EventsFilter();
  EventsFilter _mapFilter = const EventsFilter();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _homeModeCubit = sl<DashboardHomeModeCubit>();
    _tabReselectLogic = AppTabReselectTapLogic();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _tabReselectLogic.dispose();
    _homeModeCubit.close();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final saved = await sl<EventsFilterLocationStore>().read();
    await _homeModeCubit.load();
    if (!mounted) return;

    setState(() {
      _ready = true;
      if (saved.countryCode != null || saved.cityCode != null) {
        _eventsFilter = _eventsFilter.copyWith(countryCode: saved.countryCode, cityCode: saved.cityCode);
        _mapFilter = _mapFilter.copyWith(countryCode: saved.countryCode, cityCode: saved.cityCode);
      }
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
                    DashboardBottomBar(
                      currentIndex: activeIndex,
                      items: DashboardTabConfig.navItemsFor(homeMode),
                      onTabTap: (index) => _handleTabTap(tabsRouter, index),
                      onHomeTab: DashboardTabConfig.showHomeTabAccessories(activeIndex),
                      showHomeTabFilter: DashboardTabConfig.showHomeTabFilter(activeIndex),
                      showHomeTabNotifications: DashboardTabConfig.showHomeTabNotifications(activeIndex),
                      showProfileAccessories: activeIndex == DashboardTabConfig.profileTabIndex,
                      showFilterBadge: homeMode == DashboardHomeMode.map
                          ? _mapFilter.hasSelection
                          : _eventsFilter.hasSelection,
                      onFilterTap: () => unawaited(_openHomeFilter(homeMode)),
                      onNotificationsTap: () => context.router.push(const NotificationsRoute()),
                      onProfileMoreTap: _openProfileMore,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
