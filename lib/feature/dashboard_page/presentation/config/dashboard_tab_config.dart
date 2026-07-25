import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar_item.dart';
import 'package:clover/feature/dashboard_page/data/models/dashboard_home_mode.dart';

/// Конфигурация табов главного дашборда.
abstract final class DashboardTabConfig {
  static const homeTabIndex = 0;
  static const chatTabIndex = 1;
  static const profileTabIndex = 2;

  static const sideInset = 16.0;
  static const accessoryGap = 12.0;
  static const navBarHeightFigma = 64.0;

  static const routes = <PageRouteInfo>[
    DashboardHomeRoute(),
    MessageRoute(),
    ProfileRoute(),
  ];

  static List<AppNavBarItem> navItemsFor(DashboardHomeMode mode) {
    return [
      AppNavBarItem(
        icon: AppIcons.map.icon,
        label: mode == DashboardHomeMode.events ? 'Event' : 'Map',
      ),
      AppNavBarItem(icon: AppIcons.chat.icon, label: 'Chat'),
      AppNavBarItem(icon: AppIcons.user.icon, label: 'Profile'),
    ];
  }

  static bool showHomeTabAccessories(int activeIndex) {
    return activeIndex == homeTabIndex;
  }

  /// Фильтр ивентов — на ленте и на карте.
  static bool showHomeTabFilter(int activeIndex) {
    return activeIndex == homeTabIndex;
  }

  /// Уведомления — на первом табе (лента и карта).
  static bool showHomeTabNotifications(int activeIndex) {
    return activeIndex == homeTabIndex;
  }
}
