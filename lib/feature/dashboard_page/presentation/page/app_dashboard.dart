import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar_item.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AppDashboardPage extends StatelessWidget {
  const AppDashboardPage({super.key});

  static final _navItems = [
    AppNavBarItem(icon: AppIcons.map.icon, label: 'Map'),
    AppNavBarItem(icon: AppIcons.chat.icon, label: 'Chat'),
    AppNavBarItem(icon: AppIcons.user.icon, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [MapRoute(), MessageRoute(), ProfileRoute()],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        final navInsets = AppNavBar.dashboardFloatingInsets(context);

        return Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: child),
              Positioned(
                left: navInsets.left,
                right: navInsets.right,
                bottom: navInsets.bottom,
                child: AppNavBar(
                  currentIndex: tabsRouter.activeIndex,
                  items: _navItems,
                  onTap: tabsRouter.setActiveIndex,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
