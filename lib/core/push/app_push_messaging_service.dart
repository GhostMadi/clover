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

  String? _cachedToken;
  String? _syncedTokenUserId;
  Future<void>? _syncInFlight;
  Timer? _retryTimer;

  Future<void> init() async {
    if (!AppPushConfig.enabled) return;
    if (PushDevicePlatform.current == null) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
            _resetLocalCache();
          default:
            break;
        }
      });

      AppLog.i('FCM init', tag: 'Push');
      // Не блокируем cold start (permission / APNs retry до ~2s).
      if (_client.auth.currentSession != null) {
        unawaited(syncForCurrentUser());
      }
    } catch (error, stack) {
      AppLog.e('FCM init failed', tag: 'Push', error: error, stackTrace: stack);
    }
  }

  /// Вызывать **до** [SupabaseClient.auth.signOut], пока RLS ещё видит пользователя.
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
        AppLog.w('FCM token empty', tag: 'Push');
        _scheduleRetry();
        return;
      }

      _retryTimer?.cancel();
      await _upsertToken(token, userId: userId, platform: platform);
    } catch (error, stack) {
      AppLog.e('FCM sync failed', tag: 'Push', error: error, stackTrace: stack);
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!Platform.isIOS) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), () {
      unawaited(syncForCurrentUser());
    });
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await _tokenRefreshSub?.cancel();
    await _authSub?.cancel();
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    _tokenRefreshSub = null;
    _authSub = null;
    _onMessageSub = null;
    _onOpenedSub = null;
  }

  void _onForegroundMessage(RemoteMessage message) {
    _emitChatOpenIfAny(message, autoOpen: false);
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
        var apns = await _messaging.getAPNSToken();
        if (apns == null || apns.isEmpty) {
          await Future<void>.delayed(const Duration(seconds: 2));
          apns = await _messaging.getAPNSToken();
        }
        if (apns == null || apns.isEmpty) return null;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return null;
      return token;
    } on FirebaseException catch (error) {
      if (error.code == 'apns-token-not-set') return null;
      AppLog.e('FCM getToken', tag: 'Push', error: error);
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
      final short = token.length > 12 ? '${token.substring(0, 12)}…' : token;
      AppLog.i('FCM upserted · ${resolvedPlatform.storageValue} · $short', tag: 'Push');
    } catch (error, stack) {
      AppLog.e('FCM upsert failed', tag: 'Push', error: error, stackTrace: stack);
    }
  }

  void _resetLocalCache() {
    _cachedToken = null;
    _syncedTokenUserId = null;
  }
}
