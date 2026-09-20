import 'package:clover/feature/_chat_/chat/data/repository/chat_local_cache.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_chat_/chat_info/data/models/chat_participant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class ChatInfoCubit extends Cubit<ChatInfoState> {
  ChatInfoCubit(this._repository, this._localCache, this._client) : super(const ChatInfoState.initial());

  final ChatRepository _repository;
  final ChatLocalCache _localCache;
  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id.trim();

  Future<void> load({
    String? chatId,
    String? otherUserId,
    required bool isGroup,
  }) async {
    if (isClosed) return;
    emit(const ChatInfoState.loading());

    try {
      final conversationId = chatId?.trim();
      if (conversationId != null && conversationId.isNotEmpty) {
        final uid = currentUserId;
        final cachedWallpaper =
            uid == null || uid.isEmpty ? null : await _localCache.readWallpaper(uid, conversationId);

        final participantsFuture = _repository.listConversationParticipants(conversationId);
        Future<List<String>> wallpaperFuture() async {
          try {
            final remote = await _repository.getConversationWallpaper(conversationId);
            if (uid != null && uid.isNotEmpty) {
              await _localCache.writeWallpaper(uid, conversationId, remote);
            }
            return remote;
          } catch (_) {
            return cachedWallpaper ?? const [];
          }
        }

        final participants = await participantsFuture;
        final wallpaperEmojis = await wallpaperFuture();
        if (isClosed) return;
        emit(
          ChatInfoState.loaded(
            participants: participants,
            wallpaperEmojis: wallpaperEmojis,
            conversationId: conversationId,
          ),
        );
        return;
      }

      final peerId = otherUserId?.trim();
      if (!isGroup && peerId != null && peerId.isNotEmpty) {
        final peer = await _repository.getProfileBrief(peerId);
        if (isClosed) return;
        emit(
          ChatInfoState.loaded(
            participants: peer == null ? const [] : [peer],
          ),
        );
        return;
      }

      if (isClosed) return;
      emit(const ChatInfoState.loaded(participants: []));
    } catch (error) {
      if (isClosed) return;
      final message = error is ChatRepositoryException
          ? error.message
          : 'Не удалось загрузить участников';
      emit(ChatInfoState.error(message));
    }
  }

  Future<void> setWallpaperEmojis(List<String> emojis) async {
    final cur = state;
    if (cur is! ChatInfoLoaded) {
      throw const ChatRepositoryException('Чат ещё не готов');
    }
    final id = cur.conversationId?.trim();
    if (id == null || id.isEmpty) {
      throw const ChatRepositoryException('Чат ещё не создан');
    }

    final saved = await _repository.setConversationWallpaper(
      conversationId: id,
      emojis: emojis,
    );
    if (isClosed) return;

    final uid = currentUserId;
    if (uid != null && uid.isNotEmpty) {
      await _localCache.writeWallpaper(uid, id, saved);
    }

    final latest = state;
    if (latest is ChatInfoLoaded) {
      emit(latest.copyWith(wallpaperEmojis: saved));
    }
  }
}

sealed class ChatInfoState {
  const ChatInfoState();

  const factory ChatInfoState.initial() = ChatInfoInitial;
  const factory ChatInfoState.loading() = ChatInfoLoading;
  const factory ChatInfoState.loaded({
    required List<ChatParticipant> participants,
    List<String> wallpaperEmojis,
    String? conversationId,
  }) = ChatInfoLoaded;
  const factory ChatInfoState.error(String message) = ChatInfoError;
}

final class ChatInfoInitial extends ChatInfoState {
  const ChatInfoInitial();
}

final class ChatInfoLoading extends ChatInfoState {
  const ChatInfoLoading();
}

final class ChatInfoLoaded extends ChatInfoState {
  const ChatInfoLoaded({
    required this.participants,
    this.wallpaperEmojis = const [],
    this.conversationId,
  });

  final List<ChatParticipant> participants;
  final List<String> wallpaperEmojis;
  final String? conversationId;

  bool get canEditWallpaper {
    final id = conversationId?.trim();
    return id != null && id.isNotEmpty;
  }

  ChatInfoLoaded copyWith({
    List<ChatParticipant>? participants,
    List<String>? wallpaperEmojis,
    String? conversationId,
  }) {
    return ChatInfoLoaded(
      participants: participants ?? this.participants,
      wallpaperEmojis: wallpaperEmojis ?? this.wallpaperEmojis,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

final class ChatInfoError extends ChatInfoState {
  const ChatInfoError(this.message);

  final String message;
}
