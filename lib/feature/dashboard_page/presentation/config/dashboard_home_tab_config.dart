import 'package:clover/core/shared/switchable_stack.dart';
import 'package:clover/feature/dashboard_page/data/models/dashboard_home_mode.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_tab_config.dart';
import 'package:clover/feature/events_page/presentation/page/events_page.dart';
import 'package:clover/feature/map_page/presentation/page/map_page.dart';

/// Конфигурация первого таба дашборда (events ↔ map).
abstract final class DashboardHomeTabConfig {
  static const doubleTapReselectIndices = {DashboardTabConfig.homeTabIndex};

  static const variants = <SwitchableVariant<DashboardHomeMode>>[
    SwitchableVariant(key: DashboardHomeMode.events, child: EventsPage()),
    SwitchableVariant(key: DashboardHomeMode.map, child: MapPage()),
  ];
}
