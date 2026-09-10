import 'dart:async';

import 'package:clover/core/debug/app_log.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_local_cache.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Фоновый sync: `inbox_changed` → `get_message_enriched` → upsert в thread cache.
@lazySingleton
class ChatThreadCacheSync {
  ChatThreadCacheSync(
    this._repository,
    this._localCache,
    this._client,
  );

  final ChatRepository _repository;
  final ChatLocalCache _localCache;
  final SupabaseClient _client;

  final Map<String, Timer> _debounceByConversation = {};
  final Set<String> _inflightMessageIds = {};

  static const _debounce = Duration(milliseconds: 300);

  void onInboxMessage({
    required String conversationId,
    required String messageId,
  }) {
    final cid = conversationId.trim();
    final mid = messageId.trim();
    if (cid.isEmpty || mid.isEmpty) return;

    final uid = _client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) return;

    _debounceByConversation[cid]?.cancel();
    _debounceByConversation[cid] = Timer(_debounce, () {
      unawaited(_syncMessage(userId: uid, conversationId: cid, messageId: mid));
    });
  }

  Future<void> _syncMessage({
    required String userId,
    required String conversationId,
    required String messageId,
  }) async {
    if (_inflightMessageIds.contains(messageId)) return;
    _inflightMessageIds.add(messageId);

    try {
      final watermark = await _localCache.readWatermark(userId, conversationId);
      if (watermark?.messageId == messageId) return;

      final cached = await _localCache.readMessages(userId, conversationId);
      final already = cached?.any((m) => m.id == messageId) == true;
      if (already) {
        final sorted = [...cached!]
          ..sort((a, b) {
            final byTime = a.sentAt.compareTo(b.sentAt);
            if (byTime != 0) return byTime;
            return a.id.compareTo(b.id);
          });
        final head = sorted.last;
        if (watermark?.messageId != head.id) {
          await _localCache.writeWatermark(
            userId,
            conversationId,
            ChatThreadWatermark(messageId: head.id, sentAt: head.sentAt),
          );
        }
        return;
      }

      var message = await _repository.getMessageEnriched(messageId);
      if (message == null) return;

      if ((message.isMedia || message.isFile) && !message.hasAttachments) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final repaired = await _repository.getMessageEnriched(messageId);
        if (repaired != null) message = repaired;
      }

      await _localCache.upsertMessage(userId, conversationId, message);
    } catch (e, st) {
      AppLog.e('Thread cache sync failed', tag: 'ChatCache', error: e, stackTrace: st);
    } finally {
      _inflightMessageIds.remove(messageId);
    }
  }

  void dispose() {
    for (final timer in _debounceByConversation.values) {
      timer.cancel();
    }
    _debounceByConversation.clear();
    _inflightMessageIds.clear();
  }
}
