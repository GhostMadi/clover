import 'package:clover/core/extension/context.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_pill_button.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_tab_config.dart';
import 'package:flutter/material.dart';

/// Выравнивание плавающего навбара в нижней полосе.
/// Сейчас всегда [center] — бар не уезжает влево/вправо.
enum DashboardNavAlign {
  center,
}

/// Геометрия нижней панели дашборда для [DashboardBottomBar].
///
/// На Home: фильтр слева, уведомления справа от центрированного бара.
class DashboardBottomBarLayout {
  const DashboardBottomBarLayout({
    required this.navAlign,
    required this.navWidth,
    required this.navLeft,
    required this.filterLeft,
    required this.filterOpacity,
    required this.notificationsLeft,
    required this.notificationsOpacity,
    required this.rightAccessoriesLeft,
    required this.rightAccessoriesOpacity,
    required this.barHeight,
    required this.pillSize,
  });

  final DashboardNavAlign navAlign;
  final double navWidth;
  final double navLeft;
  final double filterLeft;
  final double filterOpacity;
  final double notificationsLeft;
  final double notificationsOpacity;
  final double rightAccessoriesLeft;
  final double rightAccessoriesOpacity;
  final double barHeight;
  final double pillSize;

  factory DashboardBottomBarLayout.compute(
    BuildContext context, {
    required bool onHomeTab,
    required bool showHomeTabFilter,
    required bool showHomeTabNotifications,
    required bool showProfileAccessories,
  }) {
    final bandWidth =
        MediaQuery.sizeOf(context).width - DashboardTabConfig.sideInset * 2;
    final pill = _pillSize(context);
    final gap = DashboardTabConfig.accessoryGap;
    final offscreenLeft = -(pill + gap);
    final offscreenRight = bandWidth + gap;

    final showFilter = onHomeTab && showHomeTabFilter;
    final showNotifications = onHomeTab && showHomeTabNotifications;

    // Home: фильтр слева, уведомления справа.
    final filterLeft = showFilter ? 0.0 : offscreenLeft;
    final filterOpacity = showFilter ? 1.0 : 0.0;

    final notificationsLeft =
        showNotifications ? bandWidth - pill : offscreenRight;
    final notificationsOpacity = showNotifications ? 1.0 : 0.0;

    // Profile «⋯» — тоже справа (на другой вкладке, не пересекается с уведомлениями).
    final rightAccessoriesLeft =
        showProfileAccessories ? bandWidth - pill : offscreenRight;
    final rightAccessoriesOpacity = showProfileAccessories ? 1.0 : 0.0;

    // По одной пилюле слева и справа — бар по центру без наезда.
    final sideReserve = pill;
    final preferredNavWidth = AppNavBar.dashboardPreferredWidth(context);
    final maxCenteredNavWidth = bandWidth - sideReserve * 2 - gap * 2;
    final navWidth = preferredNavWidth.clamp(0.0, maxCenteredNavWidth);
    final navLeft = (bandWidth - navWidth) / 2;

    return DashboardBottomBarLayout(
      navAlign: DashboardNavAlign.center,
      navWidth: navWidth,
      navLeft: navLeft,
      filterLeft: filterLeft,
      filterOpacity: filterOpacity,
      notificationsLeft: notificationsLeft,
      notificationsOpacity: notificationsOpacity,
      rightAccessoriesLeft: rightAccessoriesLeft,
      rightAccessoriesOpacity: rightAccessoriesOpacity,
      barHeight: context
          .heightByContext(DashboardTabConfig.navBarHeightFigma)
          .clamp(48.0, 80.0),
      pillSize: pill,
    );
  }

  static double _pillSize(BuildContext context) {
    return context
        .heightByContext(AppFunctionalPillButton.figmaSize)
        .clamp(48.0, 80.0);
  }
}
