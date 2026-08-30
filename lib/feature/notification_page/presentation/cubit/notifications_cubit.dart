import 'package:clover/feature/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/notification_page/data/repository/notifications_repository.dart';
import 'package:clover/feature/notification_page/presentation/utils/notification_date_grouping.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState.initial());

  final NotificationsRepository _repository;

  static const _pageSize = 24;

  Future<void> load() async {
    if (isClosed) return;
    emit(const NotificationsState.loading());
    await _fetch(reset: true);
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final cur = state;
    if (cur is NotificationsLoaded) {
      emit(cur.copyWith(isRefreshing: true));
    }
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    final cur = state;
    if (cur is! NotificationsLoaded || cur.isLoadingMore || !cur.hasMore || cur.items.isEmpty) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.listNotifications(limit: _pageSize, cursorItem: cur.items.last);
      if (isClosed) return;

      final filtered = _withinRetention(page.items);
      if (filtered.isEmpty) {
        emit(cur.copyWith(isLoadingMore: false, isRefreshing: false, hasMore: false));
        return;
      }

      final existingIds = cur.items.map((e) => e.id).toSet();
      final newItems = filtered.where((item) => existingIds.add(item.id)).toList(growable: false);

      emit(
        cur.copyWith(
          items: [...cur.items, ...newItems],
          hasMore: page.hasMore && newItems.isNotEmpty && filtered.length >= page.items.length,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(cur.copyWith(isLoadingMore: false, isRefreshing: false));
    }
  }

  Future<void> _fetch({required bool reset}) async {
    try {
      final page = await _repository.listNotifications(limit: _pageSize);
      if (isClosed) return;

      final items = _withinRetention(page.items);

      emit(
        NotificationsState.loaded(
          items: items,
          hasMore: page.hasMore && items.length >= page.items.length,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );

      if (items.any((e) => e.isUnread)) {
        await _repository.markRead();
        if (isClosed) return;
        final cur = state;
        if (cur is NotificationsLoaded) {
          emit(
            cur.copyWith(
              items: [
                for (final item in cur.items) item.copyWith(isUnread: false),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is NotificationsLoaded && cur.items.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false, isLoadingMore: false));
        return;
      }
      emit(NotificationsState.error('$e'));
    }
  }

  static List<NotificationItem> _withinRetention(List<NotificationItem> items) {
    return [
      for (final item in items)
        if (NotificationDateGrouping.isWithinRetention(item.createdAt)) item,
    ];
  }
}

sealed class NotificationsState {
  const NotificationsState();

  const factory NotificationsState.initial() = NotificationsInitial;
  const factory NotificationsState.loading() = NotificationsLoading;
  const factory NotificationsState.loaded({
    required List<NotificationItem> items,
    required bool hasMore,
    bool isLoadingMore,
    bool isRefreshing,
  }) = NotificationsLoaded;
  const factory NotificationsState.error(String message) = NotificationsError;
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  final List<NotificationItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

  NotificationsLoaded copyWith({
    List<NotificationItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return NotificationsLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);
  final String message;
}
