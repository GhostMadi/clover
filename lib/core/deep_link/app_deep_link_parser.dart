import 'package:clover/core/config/app_link_config.dart';
import 'package:clover/core/deep_link/app_deep_link_intent.dart';

/// Maps `clover://…` and `https://clover.app/…` to [AppDeepLinkIntent].
abstract final class AppDeepLinkParser {
  static AppDeepLinkIntent? tryParse(Uri uri) {
    final normalized = _normalize(uri);
    if (normalized == null) return null;

    final segments = normalized.segments;
    if (segments.isEmpty) return null;

    return switch (segments.first) {
      'p' || 'post' || 'posts' => _post(segments),
      'u' || 'profile' || 'user' => _profile(segments),
      'followers' => _followers(segments, normalized.query),
      'following' || 'followings' => _following(segments),
      'chat' || 'chats' => _chat(segments, normalized.query),
      'book' || 'booking' => _book(segments, normalized.query),
      'bookings' => _bookings(segments),
      'notifications' => const AppDeepLinkNotificationsIntent(),
      'bonuses' || 'bonus' => const AppDeepLinkMyBonusesIntent(),
      'home' || 'feed' || 'map' => const AppDeepLinkDashboardTabIntent(AppDeepLinkDashboardTab.home),
      'messages' || 'inbox' => const AppDeepLinkDashboardTabIntent(AppDeepLinkDashboardTab.chat),
      'me' || 'my-profile' => const AppDeepLinkDashboardTabIntent(AppDeepLinkDashboardTab.profile),
      _ => null,
    };
  }

  static _NormalizedUri? _normalize(Uri uri) {
    if (uri.scheme == AppLinkConfig.customScheme) {
      final path = uri.path.isNotEmpty ? uri.path : '/${uri.host}';
      return _NormalizedUri(_segmentsFromPath(path), uri.queryParameters);
    }

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      if (!AppLinkConfig.httpsHosts.contains(uri.host.toLowerCase())) return null;
      return _NormalizedUri(uri.pathSegments, uri.queryParameters);
    }

    return null;
  }

  static List<String> _segmentsFromPath(String path) {
    return path.split('/').where((s) => s.trim().isNotEmpty).toList();
  }

  static AppDeepLinkIntent? _post(List<String> segments) {
    final id = segments.elementAtOrNull(1)?.trim();
    if (id == null || id.isEmpty) return null;
    return AppDeepLinkPostIntent(id);
  }

  static AppDeepLinkIntent? _profile(List<String> segments) {
    final id = segments.elementAtOrNull(1)?.trim();
    if (id == null || id.isEmpty) return null;
    return AppDeepLinkProfileIntent(id);
  }

  static AppDeepLinkIntent? _followers(List<String> segments, Map<String, String> query) {
    final id = segments.elementAtOrNull(1)?.trim() ?? query['user']?.trim() ?? query['id']?.trim();
    if (id == null || id.isEmpty) return null;
    return AppDeepLinkFollowersIntent(profileId: id);
  }

  static AppDeepLinkIntent? _following(List<String> segments) {
    final id = segments.elementAtOrNull(1)?.trim();
    if (id == null || id.isEmpty) return null;
    return AppDeepLinkFollowersIntent(
      profileId: id,
      tab: AppDeepLinkFollowersTab.following,
    );
  }

  static AppDeepLinkIntent? _chat(List<String> segments, Map<String, String> query) {
    final chatId = segments.elementAtOrNull(1)?.trim() ?? query['id']?.trim();
    final withUser = query['with']?.trim() ?? query['user']?.trim();
    if (chatId != null && chatId.isNotEmpty) {
      return AppDeepLinkChatIntent(chatId: chatId);
    }
    if (withUser != null && withUser.isNotEmpty) {
      return AppDeepLinkChatIntent(otherUserId: withUser);
    }
    return const AppDeepLinkDashboardTabIntent(AppDeepLinkDashboardTab.chat);
  }

  static AppDeepLinkIntent? _book(List<String> segments, Map<String, String> query) {
    if (segments.length >= 2 && segments[1] == 'host') {
      return const AppDeepLinkHostSetupIntent();
    }

    final hostId = segments.elementAtOrNull(1)?.trim();
    if (hostId == null || hostId.isEmpty) return null;

    final serviceId = query['service']?.trim();
    return AppDeepLinkBookHostIntent(hostId: hostId, serviceId: serviceId);
  }

  static AppDeepLinkIntent? _bookings(List<String> segments) {
    if (segments.length < 2) return null;

    return switch (segments[1]) {
      'mine' || 'my' => AppDeepLinkMyBookingsIntent(
          bookingId: segments.elementAtOrNull(2)?.trim(),
        ),
      'host' => AppDeepLinkHostBookingsIntent(
          bookingId: segments.elementAtOrNull(2)?.trim(),
        ),
      _ => null,
    };
  }
}

final class _NormalizedUri {
  const _NormalizedUri(this.segments, this.query);

  final List<String> segments;
  final Map<String, String> query;
}
