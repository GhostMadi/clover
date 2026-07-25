import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/repository/my_bonuses_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class MyBonusesCubit extends Cubit<MyBonusesState> {
  MyBonusesCubit(this._repository) : super(const MyBonusesState.initial());

  final MyBonusesRepository _repository;

  Future<void> load() async {
    if (isClosed) return;
    emit(const MyBonusesState.loading());
    await _fetch();
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final cur = state;
    if (cur is MyBonusesLoaded) {
      emit(cur.copyWith(isRefreshing: true));
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final page = await _repository.listMyAccounts();
      if (isClosed) return;
      emit(
        MyBonusesState.loaded(
          items: page.items,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is MyBonusesLoaded && cur.items.isNotEmpty) {
        emit(cur.copyWith(isRefreshing: false));
        return;
      }
      emit(MyBonusesState.error('$e'));
    }
  }
}

sealed class MyBonusesState {
  const MyBonusesState();

  const factory MyBonusesState.initial() = MyBonusesInitial;
  const factory MyBonusesState.loading() = MyBonusesLoading;
  const factory MyBonusesState.loaded({
    required List<BonusAccountItem> items,
    bool isRefreshing,
  }) = MyBonusesLoaded;
  const factory MyBonusesState.error(String message) = MyBonusesError;
}

final class MyBonusesInitial extends MyBonusesState {
  const MyBonusesInitial();
}

final class MyBonusesLoading extends MyBonusesState {
  const MyBonusesLoading();
}

final class MyBonusesLoaded extends MyBonusesState {
  const MyBonusesLoaded({
    required this.items,
    this.isRefreshing = false,
  });

  final List<BonusAccountItem> items;
  final bool isRefreshing;

  MyBonusesLoaded copyWith({
    List<BonusAccountItem>? items,
    bool? isRefreshing,
  }) {
    return MyBonusesLoaded(
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

final class MyBonusesError extends MyBonusesState {
  const MyBonusesError(this.message);

  final String message;
}
