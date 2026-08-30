import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:clover/feature/_cluster_/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/_cluster_/cluster/data/repository/cluster_repository.dart';

part 'clusters_list_cubit.freezed.dart';

@injectable
class ClustersListCubit extends Cubit<ClustersListState> {
  ClustersListCubit(this._repository) : super(const ClustersListState.initial());

  final ClusterRepository _repository;
  String? _ownerId;

  /// [silent] — не сбрасывать в loading, если уже есть данные того же владельца (pull-to-refresh).
  Future<void> load(String ownerId, {bool silent = false}) async {
    if (isClosed) return;
    final id = ownerId.trim();
    if (id.isEmpty) return;

    final sameOwner = _ownerId == id;
    _ownerId = id;
    final keepVisible = silent || (sameOwner && state is _Loaded);
    if (!keepVisible) emit(const ClustersListState.loading());

    try {
      final items = await _repository.listActiveByOwnerId(id);
      if (isClosed) return;
      emit(ClustersListState.loaded(items));
    } catch (e) {
      if (isClosed) return;
      if (keepVisible && state is _Loaded) return;
      emit(ClustersListState.error('$e'));
    }
  }
}

@freezed
class ClustersListState with _$ClustersListState {
  const factory ClustersListState.initial() = _Initial;
  const factory ClustersListState.loading() = _Loading;
  const factory ClustersListState.loaded(List<ClusterModel> items) = _Loaded;
  const factory ClustersListState.error(String message) = _Error;
}
