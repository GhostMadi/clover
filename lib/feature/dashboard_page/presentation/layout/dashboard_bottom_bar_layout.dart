import 'package:clover/core/extension/context.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_pill_button.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_tab_config.dart';
import 'package:flutter/material.dart';

/// Геометрия нижней панели дашборда для [DashboardBottomBar].
class DashboardBottomBarLayout {
  const DashboardBottomBarLayout({
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
    final bandWidth = MediaQuery.sizeOf(context).width - DashboardTabConfig.sideInset * 2;
    final pill = _pillSize(context);
    final gap = DashboardTabConfig.accessoryGap;
    final offscreenLeft = -(pill + gap);

    final showFilter = onHomeTab && showHomeTabFilter;
    final showNotifications = onHomeTab && showHomeTabNotifications;

    final filterLeft = showFilter ? 0.0 : offscreenLeft;
    final filterOpacity = showFilter ? 1.0 : 0.0;

    final notificationsLeft = showNotifications ? (showFilter ? pill + gap : 0.0) : offscreenLeft;
    final notificationsOpacity = showNotifications ? 1.0 : 0.0;

    final leftAccessoryWidth = (showFilter ? pill : 0.0) + (showNotifications ? (showFilter ? gap : 0.0) + pill : 0.0);
    final rightAccessoryWidth = showProfileAccessories ? pill : 0.0;
    final leftGap = leftAccessoryWidth > 0 ? gap : 0.0;
    final rightGap = showProfileAccessories ? gap : 0.0;

    final preferredNavWidth = AppNavBar.dashboardPreferredWidth(context);
    final navWidth = preferredNavWidth.clamp(
      0.0,
      bandWidth - leftAccessoryWidth - rightAccessoryWidth - leftGap - rightGap,
    );

    final centeredNavLeft = (bandWidth - navWidth) / 2;
    final navLeft = leftAccessoryWidth > 0
        ? bandWidth - navWidth
        : showProfileAccessories
        ? bandWidth - rightAccessoryWidth - rightGap - navWidth
        : centeredNavLeft;

    return DashboardBottomBarLayout(
      navWidth: navWidth,
      navLeft: navLeft,
      filterLeft: filterLeft,
      filterOpacity: filterOpacity,
      notificationsLeft: notificationsLeft,
      notificationsOpacity: notificationsOpacity,
      rightAccessoriesLeft: showProfileAccessories ? bandWidth - pill : bandWidth + gap,
      rightAccessoriesOpacity: showProfileAccessories ? 1.0 : 0.0,
      barHeight: context.heightByContext(DashboardTabConfig.navBarHeightFigma).clamp(48.0, 80.0),
      pillSize: pill,
    );
  }

  static double _pillSize(BuildContext context) {
    return context.heightByContext(AppFunctionalPillButton.figmaSize).clamp(48.0, 80.0);
  }
}
