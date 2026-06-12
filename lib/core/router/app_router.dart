import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: RootRoute.page,
      initial: true,
      children: [
        AutoRoute(page: LoginRoute.page, initial: true),
        AutoRoute(page: PostCreateRoute.page),
        AutoRoute(page: PostCreateEditorRoute.page),
        AutoRoute(page: PostCreateComposeRoute.page),
        AutoRoute(page: PostRoute.page, type: RouteType.material()),
        AutoRoute(
          page: AppDashboardRoute.page,
          children: [
            AutoRoute(page: MapRoute.page),
            AutoRoute(page: MessageRoute.page),
            AutoRoute(page: ProfileRoute.page, initial: true),
          ],
        ),
      ],
    ),
  ];
}
