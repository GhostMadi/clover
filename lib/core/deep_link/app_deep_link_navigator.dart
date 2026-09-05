import 'package:auto_route/auto_route.dart';
import 'package:clover/core/deep_link/app_deep_link_intent.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_booking_/shared/data/repository/booking_deep_link_repository.dart';
import 'package:injectable/injectable.dart';

/// Applies [AppDeepLinkIntent] to the app router (after auth + dashboard).
@lazySingleton
class AppDeepLinkNavigator {
  AppDeepLinkNavigator(this._bookingDeepLinkRepository);

  final BookingDeepLinkRepository _bookingDeepLinkRepository;

  Future<void> navigate(StackRouter router, AppDeepLinkIntent intent) async {
    switch (intent) {
      case AppDeepLinkPostIntent(:final postId):
        await _openDashboard(router);
        await router.push(PostRoute(postId: postId));

      case AppDeepLinkProfileIntent(:final userId):
        await _openDashboard(router);
        await router.push(GuestProfileRoute(userId: userId));

      case AppDeepLinkFollowersIntent(:final profileId, :final tab):
        await _openDashboard(router);
        await router.push(
          FollowersAndFollowingsRoute(
            profileId: profileId,
            initialTabIndex: tab == AppDeepLinkFollowersTab.following ? 0 : 1,
          ),
        );

      case AppDeepLinkChatIntent(:final chatId, :final otherUserId, :final username):
        await _openDashboard(router);
        await router.push(
          ChatRoute(
            chatId: chatId,
            otherUserId: otherUserId,
            username: username,
          ),
        );

      case AppDeepLinkBookHostIntent(:final hostId, :final serviceId, :final hostDisplayName):
        await _openDashboard(router);
        await router.push(
          BookingClientRoute(
            hostId: hostId,
            hostDisplayName: hostDisplayName,
            initialServiceId: serviceId,
          ),
        );

      case AppDeepLinkMyBookingsIntent(:final bookingId):
        await _openDashboard(router);
        if (bookingId != null && bookingId.isNotEmpty) {
          await openBookingById(router, bookingId);
        } else {
          await router.push(const MyBookingsRoute());
        }

      case AppDeepLinkHostBookingsIntent(:final bookingId):
        await _openDashboard(router);
        if (bookingId != null && bookingId.isNotEmpty) {
          await openBookingById(router, bookingId);
        } else {
          await router.push(const BookingListRoute());
        }

      case AppDeepLinkNotificationsIntent():
        await _openDashboard(router);
        await router.push(const NotificationsRoute());

      case AppDeepLinkMyBonusesIntent():
        await _openDashboard(router);
        await router.push(const MyBonusesRoute());

      case AppDeepLinkHostSetupIntent():
        await _openDashboard(router);
        await router.push(const BookingListRoute());

      case AppDeepLinkDashboardTabIntent(:final tab):
        await _openDashboard(router, tab: tab);
    }
  }

  /// Notification / share link with booking id — opens client or host detail.
  Future<void> openBookingById(StackRouter router, String bookingId) async {
    final target = await _bookingDeepLinkRepository.resolveBooking(bookingId);
    if (target == null) return;

    await _openDashboard(router);

    switch (target) {
      case BookingDeepLinkClientTarget(:final item):
        await router.push(MyBookingDetailRoute(item: item));
      case BookingDeepLinkHostTarget(:final item):
        await router.push(BookingListDetailRoute(item: item));
    }
  }

  Future<void> _openDashboard(StackRouter router, {AppDeepLinkDashboardTab? tab}) async {
    final onDashboard = router.stack.any((route) => route.name == AppDashboardRoute.name);
    if (!onDashboard) {
      await router.replaceAll([const AppDashboardRoute()]);
    }

    if (tab == null) return;

    final tabsRouter = router.innerRouterOf<StackRouter>(AppDashboardRoute.name);
    if (tabsRouter == null) return;

    switch (tab) {
      case AppDeepLinkDashboardTab.home:
        await tabsRouter.navigate(const DashboardHomeRoute());
      case AppDeepLinkDashboardTab.chat:
        await tabsRouter.navigate(const MessageRoute());
      case AppDeepLinkDashboardTab.profile:
        await tabsRouter.navigate(const ProfileRoute());
    }
  }
}
