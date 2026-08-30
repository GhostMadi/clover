import 'package:clover/feature/post_share/data/models/post_share_recipient.dart';
import 'package:clover/feature/post_share/data/repository/post_share_local_cache.dart';
import 'package:clover/feature/post_share/data/repository/post_share_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class PostShareRecipientsCubit extends Cubit<PostShareRecipientsState> {
  PostShareRecipientsCubit(this._repository, this._localCache, this._client)
      : super(const PostShareRecipientsState.initial());

  final PostShareRepository _repository;
  final PostShareLocalCache _localCache;
  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id.trim();

  Future<void> load() async {
    if (isClosed) return;

    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      emit(const PostShareRecipientsState.error('Войдите в аккаунт'));
      return;
    }

    final cachedFollowing = await _localCache.readFollowing(uid);
    final cachedFrequent = await _localCache.readFrequent(uid);
    if (isClosed) return;

    if ((cachedFollowing != null && cachedFollowing.isNotEmpty) ||
        (cachedFrequent != null && cachedFrequent.isNotEmpty)) {
      emit(
        PostShareRecipientsState.loaded(
          following: cachedFollowing ?? const [],
          frequent: cachedFrequent ?? const [],
          isFromCache: true,
        ),
      );
    } else {
      emit(const PostShareRecipientsState.loading());
    }

    try {
      final results = await Future.wait([
        _repository.listFollowing(),
        _repository.listFrequentRecipients(limit: 10),
      ]);
      if (isClosed) return;

      final following = results[0];
      final frequent = results[1];

      await _localCache.writeFollowing(uid, following);
      await _localCache.writeFrequent(uid, frequent);
      if (isClosed) return;

      emit(
        PostShareRecipientsState.loaded(
          following: following,
          frequent: frequent,
          isFromCache: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      final cur = state;
      if (cur is PostShareRecipientsLoaded &&
          (cur.following.isNotEmpty || cur.frequent.isNotEmpty)) {
        emit(cur.copyWith(isRefreshing: false));
        return;
      }
      emit(PostShareRecipientsState.error('$e'));
    }
  }
}

sealed class PostShareRecipientsState {
  const PostShareRecipientsState();

  const factory PostShareRecipientsState.initial() = PostShareRecipientsInitial;
  const factory PostShareRecipientsState.loading() = PostShareRecipientsLoading;
  const factory PostShareRecipientsState.loaded({
    required List<PostShareRecipient> following,
    required List<PostShareRecipient> frequent,
    bool isFromCache,
    bool isRefreshing,
  }) = PostShareRecipientsLoaded;
  const factory PostShareRecipientsState.error(String message) = PostShareRecipientsError;
}

final class PostShareRecipientsInitial extends PostShareRecipientsState {
  const PostShareRecipientsInitial();
}

final class PostShareRecipientsLoading extends PostShareRecipientsState {
  const PostShareRecipientsLoading();
}

final class PostShareRecipientsLoaded extends PostShareRecipientsState {
  const PostShareRecipientsLoaded({
    required this.following,
    required this.frequent,
    this.isFromCache = false,
    this.isRefreshing = false,
  });

  final List<PostShareRecipient> following;
  final List<PostShareRecipient> frequent;
  final bool isFromCache;
  final bool isRefreshing;

  PostShareRecipientsLoaded copyWith({
    List<PostShareRecipient>? following,
    List<PostShareRecipient>? frequent,
    bool? isFromCache,
    bool? isRefreshing,
  }) {
    return PostShareRecipientsLoaded(
      following: following ?? this.following,
      frequent: frequent ?? this.frequent,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class PostShareRecipientsError extends PostShareRecipientsState {
  const PostShareRecipientsError(this.message);
  final String message;
}
