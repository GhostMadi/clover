/// Parsed in-app navigation target from an external URL.
sealed class AppDeepLinkIntent {
  const AppDeepLinkIntent();
}

final class AppDeepLinkPostIntent extends AppDeepLinkIntent {
  const AppDeepLinkPostIntent(this.postId);

  final String postId;
}

final class AppDeepLinkProfileIntent extends AppDeepLinkIntent {
  const AppDeepLinkProfileIntent(this.userId);

  final String userId;
}

final class AppDeepLinkFollowersIntent extends AppDeepLinkIntent {
  const AppDeepLinkFollowersIntent({
    required this.profileId,
    this.tab = AppDeepLinkFollowersTab.followers,
  });

  final String profileId;
  final AppDeepLinkFollowersTab tab;
}

enum AppDeepLinkFollowersTab { followers, following }

final class AppDeepLinkChatIntent extends AppDeepLinkIntent {
  const AppDeepLinkChatIntent({
    this.chatId,
    this.otherUserId,
    this.username = 'Чат',
  });

  final String? chatId;
  final String? otherUserId;
  final String username;
}

final class AppDeepLinkBookHostIntent extends AppDeepLinkIntent {
  const AppDeepLinkBookHostIntent({
    required this.hostId,
    this.serviceId,
    this.hostDisplayName = 'Мастер',
  });

  final String hostId;
  final String? serviceId;
  final String hostDisplayName;
}

final class AppDeepLinkMyBookingsIntent extends AppDeepLinkIntent {
  const AppDeepLinkMyBookingsIntent({this.bookingId});

  final String? bookingId;
}

final class AppDeepLinkHostBookingsIntent extends AppDeepLinkIntent {
  const AppDeepLinkHostBookingsIntent({this.bookingId});

  final String? bookingId;
}

final class AppDeepLinkNotificationsIntent extends AppDeepLinkIntent {
  const AppDeepLinkNotificationsIntent();
}

final class AppDeepLinkMyBonusesIntent extends AppDeepLinkIntent {
  const AppDeepLinkMyBonusesIntent();
}

final class AppDeepLinkHostSetupIntent extends AppDeepLinkIntent {
  const AppDeepLinkHostSetupIntent();
}

final class AppDeepLinkDashboardTabIntent extends AppDeepLinkIntent {
  const AppDeepLinkDashboardTabIntent(this.tab);

  final AppDeepLinkDashboardTab tab;
}

enum AppDeepLinkDashboardTab { home, chat, profile }
