import 'dart:async';
import 'dart:io' show Platform;

import 'package:clover/core/debug/app_log.dart';
import 'package:clover/core/push/app_push_config.dart';
import 'package:clover/core/push/firebase_messaging_background.dart';
import 'package:clover/core/push/push_device_platform.dart';
import 'package:clover/core/push/push_device_token_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM: permission → token → upsert в Supabase; refresh + logout detach.
@lazySingleton
class AppPushMessagingService {
  AppPushMessagingService(this._client, this._tokenRepository);

  final SupabaseClient _client;
  final PushDeviceTokenRepository _tokenRepository;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<AuthState>? _authSub;

  String? _cachedToken;
  String? _syncedTokenUserId;

  Future<void> init() async {
    if (!AppPushConfig.enabled) return;
    if (PushDevicePlatform.current == null) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        unawaited(_syncToken(token));
      });

      await _authSub?.cancel();
      _authSub = _client.auth.onAuthStateChange.listen((state) {
        switch (state.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.initialSession:
            if (state.session != null) {
              unawaited(syncForCurrentUser());
            }
          case AuthChangeEvent.signedOut:
            _resetLocalCache();
          default:
            break;
        }
      });

      AppLog.i('FCM init', tag: 'Push');
      if (_client.auth.currentSession != null) {
        await syncForCurrentUser();
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

    final token = _cachedToken ?? await _resolveFcmToken();
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

  Future<void> syncForCurrentUser() async {
    if (!AppPushConfig.enabled) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = PushDevicePlatform.current;
    if (platform == null) return;

    try {
      final allowed = await _requestPermission();
      if (!allowed) {
        AppLog.w('FCM permission denied', tag: 'Push');
        return;
      }

      final token = await _resolveFcmToken();
      if (token == null || token.isEmpty) {
        AppLog.w('FCM token empty (APNs not ready?)', tag: 'Push');
        return;
      }

      await _syncToken(token, userId: userId, platform: platform);
    } catch (error, stack) {
      AppLog.e('FCM sync failed', tag: 'Push', error: error, stackTrace: stack);
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _authSub?.cancel();
    _tokenRefreshSub = null;
    _authSub = null;
  }

  /// iOS: FCM ждёт APNs; на симуляторе APNs нет → null без краша.
  Future<String?> _resolveFcmToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) return null;
      }

      return await _messaging.getToken();
    } on FirebaseException catch (error) {
      if (error.code == 'apns-token-not-set') return null;
      AppLog.e('FCM getToken', tag: 'Push', error: error);
      return null;
    } catch (error, stack) {
      AppLog.e('FCM getToken', tag: 'Push', error: error, stackTrace: stack);
      return null;
    }
  }

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _syncToken(
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
