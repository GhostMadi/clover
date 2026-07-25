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
        AutoRoute(page: MarkerCreateRoute.page),
        AutoRoute(page: MarkerCreateEditorRoute.page),
        AutoRoute(page: MarkerCreateComposeRoute.page),
        AutoRoute(page: ClusterCreateRoute.page),
        AutoRoute(page: ClusterCreateEditorRoute.page),
        AutoRoute(page: ClusterCreateComposeRoute.page),
        AutoRoute(page: PostRoute.page, type: RouteType.material()),
        AutoRoute(page: SettingsRoute.page),
        AutoRoute(page: SettingsResourcesRoute.page),
        AutoRoute(page: SettingsFiltersRoute.page),
        AutoRoute(page: BookingListRoute.page),
        AutoRoute(page: BookingListDetailRoute.page, type: RouteType.material()),
        AutoRoute(page: BookingAnalyticsRoute.page),
        AutoRoute(page: BookingCreateRoute.page),
        AutoRoute(page: BookingServiceCreateRoute.page),
        AutoRoute(page: BookingServiceEditRoute.page),
        AutoRoute(page: BookingScheduleSettingsRoute.page),
        AutoRoute(page: BookingClientRoute.page),
        AutoRoute(page: MyBookingsRoute.page),
        AutoRoute(page: MyBookingDetailRoute.page),
        AutoRoute(page: MyBonusesRoute.page),
        AutoRoute(page: BonusHistoryRoute.page),
        AutoRoute(page: BonusProgramSettingsRoute.page),
        AutoRoute(page: SettingsArchiveRoute.page),
        AutoRoute(page: SavedPostsRoute.page),
        AutoRoute(page: SettingsAccountRoute.page),
        AutoRoute(page: PostArchiveRoute.page),
        AutoRoute(page: EventArchiveRoute.page),
        AutoRoute(page: ClusterArchiveRoute.page),
        AutoRoute(page: LocationRoute.page),
        AutoRoute(page: LocationCreateRoute.page),
        AutoRoute(page: FollowersAndFollowingsRoute.page),
        AutoRoute(page: NotificationsRoute.page),
        AutoRoute(page: GuestProfileRoute.page),
        AutoRoute(page: EditProfileRoute.page),
        AutoRoute(page: EditProfileBannerPickRoute.page),
        AutoRoute(page: EditProfileBannerEditorRoute.page),
        AutoRoute(page: EditProfileBannerConfirmRoute.page),
        AutoRoute(page: EditProfileAvatarPickRoute.page),
        AutoRoute(page: EditProfileAvatarEditorRoute.page),
        AutoRoute(page: EditProfileAvatarConfirmRoute.page),
        AutoRoute(page: ChatRoute.page),
        AutoRoute(
          page: AppDashboardRoute.page,
          children: [
            AutoRoute(page: DashboardHomeRoute.page),
            AutoRoute(page: MessageRoute.page),
            AutoRoute(page: ProfileRoute.page, initial: true),
          ],
        ),
      ],
    ),
  ];
}
