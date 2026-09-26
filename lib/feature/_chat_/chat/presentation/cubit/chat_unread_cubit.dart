import 'dart:async';

import 'package:clover/core/debug/app_log.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_thread_cache_sync.dart';
import 'package:clover/feature/_chat_/chat/presentation/chat_active_thread.dart';
import 'package:clover/feature/_chat_/chat/presentation/chat_push_open_bus.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Единственный владелец Realtime `chat_inbox_<uid>`:
/// бейдж Chat + in-app баннер + сигнал списку + thread cache sync.
@lazySingleton
class ChatUnreadCubit extends Cubit<int> {
  ChatUnreadCubit(
    this._repository,
    this._client,
    this._openBus,
    this._activeThread,
    this._threadCacheSync,
  ) : super(0);

  final ChatRepository _repository;
  final SupabaseClient _client;
  final ChatPushOpenBus _openBus;
  final ChatActiveThread _activeThread;
  final ChatThreadCacheSync _threadCacheSync;

  final _inboxChangedController = StreamController<void>.broadcast();

  /// Список чатов (и др.) подписываются сюда вместо второго канала на тот же topic.
  Stream<void> get inboxChanged => _inboxChangedController.stream;

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;
  Timer? _debounce;
  Timer? _resumeDebounce;
  Future<void>? _refreshInFlight;
  bool _started = false;

  Future<void> start() async {
    if (_started) {
      if (_client.auth.currentSession != null) {
        await _bindInbox();
        await refresh();
      }
      return;
    }
    _started = true;

    await _authSub?.cancel();
    _authSub = _client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.initialSession:
          if (state.session != null) {
            unawaited(_bindInbox());
            unawaited(refresh());
          }
        case AuthChangeEvent.signedOut:
          _unbindInbox();
          if (!isClosed) emit(0);
        default:
          break;
      }
    });

    if (_client.auth.currentSession != null) {
      await _bindInbox();
      await refresh();
    }
  }

  /// После resume: подождать сеть, не бить RPC сразу.
  void refreshAfterResume() {
    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() {
    return _refreshInFlight ??= _refreshOnce().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _refreshOnce() async {
    if (isClosed) return;
    try {
      final count = await _repository.countUnreadMessages();
      if (isClosed) return;
      emit(count < 0 ? 0 : count);
    } catch (e, _) {
      AppLog.w('Chat unread refresh skipped · $e', tag: 'ChatInbox');
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(refresh());
    });
  }

  Future<void> _bindInbox() async {
    final uid = _client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;

    _unbindInbox();
    _channel = _client.channel('chat_inbox_$uid')
      ..onBroadcast(
        event: 'inbox_changed',
        callback: _onInboxChanged,
      )
      ..subscribe();
  }

  void _onInboxChanged(Map<String, dynamic> payload) {
    if (!_inboxChangedController.isClosed) {
      _inboxChangedController.add(null);
    }
    _scheduleRefresh();
    _maybeSyncThreadCache(payload);
    _maybeShowInAppBanner(payload);
  }

  void _maybeSyncThreadCache(Map<String, dynamic> payload) {
    final data = _unwrapBroadcastPayload(payload);
    if (data == null) return;

    final reason = data['reason']?.toString();
    if (reason == 'peer_read') return;

    final conversationId = data['conversation_id']?.toString().trim() ?? '';
    final messageId = data['message_id']?.toString().trim() ?? '';
    if (conversationId.isEmpty || messageId.isEmpty) return;

    // Открытый тред пишет кэш сам через message_enriched — дублировать не нужно.
    if (_activeThread.isOpen(conversationId)) return;

    _threadCacheSync.onInboxMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  void _maybeShowInAppBanner(Map<String, dynamic> payload) {
    final data = _unwrapBroadcastPayload(payload);
    if (data == null) return;

    final reason = data['reason']?.toString();
    if (reason == 'peer_read') return;

    final me = _client.auth.currentUser?.id.trim();
    final senderId = data['sender_id']?.toString().trim();
    if (me == null || senderId == null || senderId.isEmpty || senderId == me) return;

    final conversationId = data['conversation_id']?.toString().trim() ?? '';
    if (conversationId.isEmpty) return;
    if (_activeThread.isOpen(conversationId)) return;

    final peerRaw = (data['sender_username'] ?? data['peer_username'] ?? 'chat').toString().trim();
    final peer = peerRaw == 'chat' || peerRaw.isEmpty ? lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).push_chat_fallback_title : peerRaw;
    final preview = _localizeInboxPreview(
      data['preview']?.toString().trim(),
      kind: data['kind']?.toString().trim(),
    );
    final messageId = data['message_id']?.toString().trim();

    _openBus.emit(
      ChatPushOpenRequest(
        conversationId: conversationId,
        peerUsername: peer,
        preview: preview,
        messageId: (messageId == null || messageId.isEmpty) ? null : messageId,
        autoOpen: false,
      ),
    );
  }

  /// EN keys from inbox broadcast (`photo` / `file` / …) → localized label; free text as-is.
  String _localizeInboxPreview(String? preview, {String? kind}) {
    final raw = preview?.trim() ?? '';
    final key = raw.toLowerCase();
    final l10n = lookupAppLocalizations(sl<AppLocaleCubit>().state.locale);
    final labels = <String, String>{
      'photo': l10n.chat_preview_photo,
      'file': l10n.chat_preview_file,
      'post': l10n.chat_preview_post,
      'message': l10n.chat_preview_message,
      'system': l10n.chat_preview_system,
    };
    if (labels.containsKey(key)) return labels[key]!;

    final k = kind?.trim() ?? '';
    if (raw.isEmpty) {
      return switch (k) {
        'media' => l10n.chat_preview_photo,
        'file' => l10n.chat_preview_file,
        'post_ref' => l10n.chat_preview_post,
        'system' => l10n.chat_preview_system,
        _ => l10n.chat_preview_message,
      };
    }
    return raw;
  }

  /// Supabase Realtime may nest as `{ payload: {...} }` or pass fields at top level.
  Map<dynamic, dynamic>? _unwrapBroadcastPayload(Map<String, dynamic> payload) {
    final nested = payload['payload'];
    if (nested is Map) return nested;
    if (payload.containsKey('conversation_id') || payload.containsKey('sender_id')) {
      return payload;
    }
    return null;
  }

  void _unbindInbox() {
    _debounce?.cancel();
    _resumeDebounce?.cancel();
    _channel?.unsubscribe();
    _channel = null;
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    _resumeDebounce?.cancel();
    await _authSub?.cancel();
    _unbindInbox();
    _threadCacheSync.dispose();
    await _inboxChangedController.close();
    return super.close();
  }
}
