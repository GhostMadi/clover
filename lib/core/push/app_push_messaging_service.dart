import 'dart:async';
import 'dart:io' show Platform;

import 'package:clover/core/debug/app_log.dart';
import 'package:clover/core/push/app_push_config.dart';
import 'package:clover/core/push/firebase_messaging_background.dart';
import 'package:clover/core/push/push_device_platform.dart';
import 'package:clover/core/push/push_device_token_repository.dart';
import 'package:clover/feature/_chat_/chat/presentation/chat_push_open_bus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM: permission → APNs (iOS) → token → upsert; chat open via [ChatPushOpenBus].
@lazySingleton
class AppPushMessagingService {
  AppPushMessagingService(this._client, this._tokenRepository, this._chatOpenBus);

  final SupabaseClient _client;
  final PushDeviceTokenRepository _tokenRepository;
  final ChatPushOpenBus _chatOpenBus;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  final _foregroundBannerController =
      StreamController<AppPushForegroundBanner>.broadcast();

  String? _cachedToken;
  String? _syncedTokenUserId;
  Future<void>? _syncInFlight;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  static const _maxSyncRetries = 6;

  /// Android foreground: FCM не рисует tray — слушай и покажи [AppSnackBar].
  Stream<AppPushForegroundBanner> get foregroundBanners =>
      _foregroundBannerController.stream;

  Future<void> init() async {
    if (!AppPushConfig.enabled) return;
    if (PushDevicePlatform.current == null) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // iOS: системный баннер и в foreground (иначе только onMessage без UI).
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        unawaited(_upsertToken(token));
      });

      await _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      await _onOpenedSub?.cancel();
      _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpen);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _emitChatOpenIfAny(initial, autoOpen: true);
      }

      await _authSub?.cancel();
      _authSub = _client.auth.onAuthStateChange.listen((state) {
        switch (state.event) {
          case AuthChangeEvent.signedIn:
            unawaited(syncForCurrentUser());
          case AuthChangeEvent.signedOut:
            _retryTimer?.cancel();
            _retryAttempt = 0;
            _resetLocalCache();
          default:
            break;
        }
      });

      AppLog.i('FCM init', tag: 'Push');
      if (_client.auth.currentSession != null) {
        unawaited(syncForCurrentUser());
      }
    } catch (error, stack) {
      AppLog.e('FCM init failed', tag: 'Push', error: error, stackTrace: stack);
    }
  }

  Future<void> detachForSignOut() async {
    if (!AppPushConfig.enabled) {
      _resetLocalCache();
      return;
    }

    final token = _cachedToken;
    if (token == null || token.isEmpty) {
      _resetLocalCache();
      return;
    }

    try {
      await _tokenRepository.deleteToken(token);
      AppLog.i('FCM token detached', tag: 'Push');
    } catch (error, stack) {
      AppLog.e('FCM detach failed', tag: 'Push', error: error, stackTrace: stack);
    } finally {
      _resetLocalCache();
    }
  }

  Future<void> syncForCurrentUser() {
    final existing = _syncInFlight;
    if (existing != null) return existing;

    late final Future<void> future;
    future = _syncOnce().whenComplete(() {
      if (identical(_syncInFlight, future)) {
        _syncInFlight = null;
      }
    });
    _syncInFlight = future;
    return future;
  }

  Future<void> _syncOnce() async {
    if (!AppPushConfig.enabled) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = PushDevicePlatform.current;
    if (platform == null) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        AppLog.w('FCM permission · ${settings.authorizationStatus.name}', tag: 'Push');
        return;
      }

      final token = await _resolveFcmToken();
      if (token == null || token.isEmpty) {
        AppLog.w(_emptyTokenHint(), tag: 'Push');
        _scheduleRetry();
        return;
      }

      _retryTimer?.cancel();
      _retryAttempt = 0;
      await _upsertToken(token, userId: userId, platform: platform);
    } catch (error, stack) {
      AppLog.e('FCM sync failed', tag: 'Push', error: error, stackTrace: stack);
      _scheduleRetry();
    }
  }

  String _emptyTokenHint() {
    if (Platform.isIOS) {
      if (kReleaseMode) {
        return 'FCM token empty · iOS: нужен aps-environment=production в Release/TestFlight + APNs key в Firebase';
      }
      return 'FCM token empty · iOS: симулятор без APNs или APNs ещё не готов (подожди / перезапусти на реальном iPhone)';
    }
    return 'FCM token empty · Android: Google Play Services / google-services.json';
  }

  void _scheduleRetry() {
    if (_retryAttempt >= _maxSyncRetries) return;
    _retryAttempt += 1;
    final delay = Duration(seconds: 2 * _retryAttempt);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      unawaited(syncForCurrentUser());
    });
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await _tokenRefreshSub?.cancel();
    await _authSub?.cancel();
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _foregroundBannerController.close();
    _tokenRefreshSub = null;
    _authSub = null;
    _onMessageSub = null;
    _onOpenedSub = null;
  }

  void _onForegroundMessage(RemoteMessage message) {
    final kind = (message.data['kind'] ?? '').toString().trim();
    final title = (message.notification?.title ?? '').trim();
    final body = (message.notification?.body ?? '').trim();
    AppLog.i('FCM foreground · $kind · $title', tag: 'Push');

    // iOS: баннер рисует система (presentation options + AppDelegate.willPresent).
    if (Platform.isIOS) return;

    // Android: tray в foreground нет — chat → Instagram-баннер, остальное → общий snack.
    if (kind == 'chat_message') {
      _emitChatOpenIfAny(message, autoOpen: false);
      return;
    }

    if (title.isEmpty && body.isEmpty) return;
    if (_foregroundBannerController.isClosed) return;
    _foregroundBannerController.add(
      AppPushForegroundBanner(
        title: title.isEmpty ? 'Clover' : title,
        body: body,
        kind: kind,
      ),
    );
  }

  void _onNotificationOpen(RemoteMessage message) {
    _emitChatOpenIfAny(message, autoOpen: true);
  }

  void _emitChatOpenIfAny(RemoteMessage message, {required bool autoOpen}) {
    final data = message.data;
    if ((data['kind'] ?? '').toString().trim() != 'chat_message') return;

    final conversationId = (data['conversation_id'] ?? '').toString().trim();
    if (conversationId.isEmpty) return;

    final peer = (data['peer_username'] ?? message.notification?.title ?? 'Чат')
        .toString()
        .trim();
    final preview = (message.notification?.body ?? data['body'] ?? '').toString().trim();

    _chatOpenBus.emit(
      ChatPushOpenRequest(
        conversationId: conversationId,
        peerUsername: peer.isEmpty ? 'Чат' : peer,
        isGroup: (data['is_group'] ?? '').toString() == 'true',
        autoOpen: autoOpen,
        preview: preview.isEmpty ? null : preview,
        messageId: (data['message_id'] ?? '').toString().trim().isEmpty
            ? null
            : (data['message_id'] ?? '').toString().trim(),
      ),
    );
  }

  Future<String?> _resolveFcmToken() async {
    try {
      if (Platform.isIOS) {
        String? apns;
        for (var i = 0; i < 6; i++) {
          apns = await _messaging.getAPNSToken();
          if (apns != null && apns.isNotEmpty) break;
          await Future<void>.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
        if (apns == null || apns.isEmpty) {
          AppLog.w('APNs token not ready yet', tag: 'Push');
          return null;
        }
        AppLog.i('APNs ready · len=${apns.length}', tag: 'Push');
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return null;
      AppLog.i('FCM token · $token', tag: 'Push');
      return token;
    } on FirebaseException catch (error) {
      if (error.code == 'apns-token-not-set') return null;
      AppLog.e('FCM getToken · ${error.code}', tag: 'Push', error: error);
      return null;
    } catch (error, stack) {
      AppLog.e('FCM getToken', tag: 'Push', error: error, stackTrace: stack);
      return null;
    }
  }

  Future<void> _upsertToken(
    String token, {
    String? userId,
    PushDevicePlatform? platform,
  }) async {
    final resolvedUserId = userId ?? _client.auth.currentUser?.id;
    final resolvedPlatform = platform ?? PushDevicePlatform.current;
    if (resolvedUserId == null || resolvedPlatform == null) return;
    if (_syncedTokenUserId == resolvedUserId && _cachedToken == token) return;

    try {
      await _tokenRepository.upsert(
        userId: resolvedUserId,
        token: token,
        platform: resolvedPlatform,
      );
      _cachedToken = token;
      _syncedTokenUserId = resolvedUserId;
      AppLog.i(
        'FCM upserted · ${resolvedPlatform.storageValue} · len=${token.length}',
        tag: 'Push',
      );
    } catch (error, stack) {
      AppLog.e('FCM upsert failed', tag: 'Push', error: error, stackTrace: stack);
    }
  }

  void _resetLocalCache() {
    _cachedToken = null;
    _syncedTokenUserId = null;
  }
}

class AppPushForegroundBanner {
  const AppPushForegroundBanner({
    required this.title,
    required this.body,
    required this.kind,
  });

  final String title;
  final String body;
  final String kind;
}
