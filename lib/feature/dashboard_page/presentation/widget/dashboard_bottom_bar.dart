import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_pill_button.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar_item.dart';
import 'package:clover/feature/dashboard_page/presentation/config/dashboard_tab_config.dart';
import 'package:clover/feature/dashboard_page/presentation/layout/dashboard_bottom_bar_layout.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/profile_dashboard_accessories.dart';
import 'package:flutter/material.dart';

/// Нижняя панель дашборда.
///
/// Навбар всегда по центру.
/// На Home: фильтр слева, уведомления справа; на Profile: «ещё» справа.
///
/// Навбар — простой [AppNavBar] в [AnimatedPositioned]-слоте.
class DashboardBottomBar extends StatelessWidget {
  const DashboardBottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTabTap,
    required this.onHomeTab,
    required this.showHomeTabFilter,
    required this.showHomeTabNotifications,
    required this.showProfileAccessories,
    required this.showFilterBadge,
    required this.showNotificationsBadge,
    required this.onFilterTap,
    required this.onNotificationsTap,
    required this.onProfileMoreTap,
  });

  final int currentIndex;
  final List<AppNavBarItem> items;
  final ValueChanged<int> onTabTap;
  final bool onHomeTab;
  final bool showHomeTabFilter;
  final bool showHomeTabNotifications;
  final bool showProfileAccessories;
  final bool showFilterBadge;
  final bool showNotificationsBadge;
  final VoidCallback onFilterTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileMoreTap;

  @override
  Widget build(BuildContext context) {
    final navInsets = AppNavBar.dashboardFloatingInsets(context);
    final layout = DashboardBottomBarLayout.compute(
      context,
      onHomeTab: onHomeTab,
      showHomeTabFilter: showHomeTabFilter,
      showHomeTabNotifications: showHomeTabNotifications,
      showProfileAccessories: showProfileAccessories,
    );

    return Positioned(
      left: DashboardTabConfig.sideInset,
      right: DashboardTabConfig.sideInset,
      bottom: navInsets.bottom,
      height: layout.barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _AnimatedAccessoryPill(
            left: layout.filterLeft,
            opacity: layout.filterOpacity,
            interactive: onHomeTab && showHomeTabFilter,
            child: AppFunctionalPillButton(
              icon: AppIcons.filterList.icon,
              customColor: context.colors.functionalSoftBlue,
              iconColor: context.colors.functionalSoftBlueIcon,
              showBadge: showFilterBadge,
              onTap: onFilterTap,
            ),
          ),
          _AnimatedAccessoryPill(
            left: layout.notificationsLeft,
            opacity: layout.notificationsOpacity,
            interactive: onHomeTab && showHomeTabNotifications,
            child: AppFunctionalPillButton(
              icon: AppIcons.notificationsOutlined.icon,
              customColor: context.colors.functionalSoftOrange,
              iconColor: context.colors.functionalSoftOrangeIcon,
              showBadge: showNotificationsBadge,
              onTap: onNotificationsTap,
            ),
          ),
          _AnimatedRightAccessories(
            left: layout.rightAccessoriesLeft,
            opacity: layout.rightAccessoriesOpacity,
            interactive: showProfileAccessories,
            onProfileMoreTap: onProfileMoreTap,
          ),
          AnimatedPositioned(
            duration: AppNavBar.dashboardLayoutDuration,
            curve: AppNavBar.dashboardLayoutCurve,
            left: layout.navLeft,
            bottom: 0,
            width: layout.navWidth,
            height: layout.barHeight,
            // Клип на самом AppNavBar — Stack оставляем Clip.none для аксессуаров.
            child: AppNavBar(
              currentIndex: currentIndex,
              items: items,
              onTap: onTabTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedAccessoryPill extends StatelessWidget {
  const _AnimatedAccessoryPill({
    required this.left,
    required this.opacity,
    required this.interactive,
    required this.child,
  });

  final double left;
  final double opacity;
  final bool interactive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: AppNavBar.dashboardLayoutDuration,
      curve: AppNavBar.dashboardLayoutCurve,
      left: left,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !interactive,
        child: AnimatedOpacity(
          duration: AppNavBar.dashboardLayoutDuration,
          curve: AppNavBar.dashboardLayoutCurve,
          opacity: opacity,
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedRightAccessories extends StatelessWidget {
  const _AnimatedRightAccessories({
    required this.left,
    required this.opacity,
    required this.interactive,
    required this.onProfileMoreTap,
  });

  final double left;
  final double opacity;
  final bool interactive;
  final VoidCallback onProfileMoreTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: AppNavBar.dashboardLayoutDuration,
      curve: AppNavBar.dashboardLayoutCurve,
      left: left,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !interactive,
        child: AnimatedOpacity(
          duration: AppNavBar.dashboardLayoutDuration,
          curve: AppNavBar.dashboardLayoutCurve,
          opacity: opacity,
          child: ProfileDashboardAccessories(onMoreTap: onProfileMoreTap),
        ),
      ),
    );
  }
}
