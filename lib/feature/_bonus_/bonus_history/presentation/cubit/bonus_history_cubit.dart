import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';
import 'package:clover/feature/_bonus_/bonus_history/data/repository/bonus_history_repository.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BonusHistoryCubit extends Cubit<BonusHistoryState> {
  BonusHistoryCubit(this._repository) : super(const BonusHistoryState.initial());

  final BonusHistoryRepository _repository;

  static const _pageSize = 50;

  Future<void> load(BonusAccountItem account) async {
    if (isClosed) return;
    emit(BonusHistoryState.loading(account: account));
    await _fetch(account: account, reset: true);
  }

  Future<void> refresh() async {
    final cur = state;
    if (cur is! BonusHistoryLoaded) return;
    emit(cur.copyWith(isRefreshing: true));
    await _fetch(account: cur.account, reset: true);
  }

  Future<void> loadMore() async {
    final cur = state;
    if (cur is! BonusHistoryLoaded || cur.isLoadingMore || !cur.hasMore || cur.entries.isEmpty) return;

    emit(cur.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.listHistory(
        hostId: cur.account.hostId,
        limit: _pageSize,
        cursorItem: cur.entries.last,
      );
      if (isClosed) return;

      final existingIds = cur.entries.map((e) => e.id).toSet();
      final newEntries = page.items.where((e) => existingIds.add(e.id)).toList(growable: false);

      emit(
        cur.copyWith(
          balance: page.balance,
          entries: [...cur.entries, ...newEntries],
          hasMore: page.hasMore && newEntries.isNotEmpty,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(cur.copyWith(isLoadingMore: false, isRefreshing: false));
    }
  }

  Future<void> _fetch({required BonusAccountItem account, required bool reset}) async {
    try {
      final page = await _repository.listHistory(hostId: account.hostId, limit: _pageSize);
      if (isClosed) return;

      final refreshedAccount = account.copyWith(balance: page.balance);

      emit(
        BonusHistoryState.loaded(
          account: refreshedAccount,
          balance: page.balance,
          entries: page.items,
          hasMore: page.hasMore,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is BonusHistoryLoaded && cur.entries.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false, isLoadingMore: false));
        return;
      }
      emit(BonusHistoryState.error(account: account, message: '$e'));
    }
  }
}

sealed class BonusHistoryState {
  const BonusHistoryState();

  const factory BonusHistoryState.initial() = BonusHistoryInitial;
  const factory BonusHistoryState.loading({required BonusAccountItem account}) = BonusHistoryLoading;
  const factory BonusHistoryState.loaded({
    required BonusAccountItem account,
    required int balance,
    required List<BonusHistoryEntry> entries,
    required bool hasMore,
    bool isLoadingMore,
    bool isRefreshing,
  }) = BonusHistoryLoaded;
  const factory BonusHistoryState.error({
    required BonusAccountItem account,
    required String message,
  }) = BonusHistoryError;
}

final class BonusHistoryInitial extends BonusHistoryState {
  const BonusHistoryInitial();
}

final class BonusHistoryLoading extends BonusHistoryState {
  const BonusHistoryLoading({required this.account});

  final BonusAccountItem account;
}

final class BonusHistoryLoaded extends BonusHistoryState {
  const BonusHistoryLoaded({
    required this.account,
    required this.balance,
    required this.entries,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  final BonusAccountItem account;
  final int balance;
  final List<BonusHistoryEntry> entries;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

  BonusHistoryLoaded copyWith({
    BonusAccountItem? account,
    int? balance,
    List<BonusHistoryEntry>? entries,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return BonusHistoryLoaded(
      account: account ?? this.account,
      balance: balance ?? this.balance,
      entries: entries ?? this.entries,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class BonusHistoryError extends BonusHistoryState {
  const BonusHistoryError({required this.account, required this.message});

  final BonusAccountItem account;
  final String message;
}
