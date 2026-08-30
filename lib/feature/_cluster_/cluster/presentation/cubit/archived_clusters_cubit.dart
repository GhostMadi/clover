import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:clover/feature/cluster/data/models/cluster_model.dart';
import 'package:clover/feature/cluster/data/repository/cluster_repository.dart';

part 'archived_clusters_cubit.freezed.dart';

@injectable
class ArchivedClustersCubit extends Cubit<ArchivedClustersState> {
  ArchivedClustersCubit(this._repository) : super(const ArchivedClustersState.initial());

  final ClusterRepository _repository;

  Future<void> load(String ownerId) async {
    if (isClosed) return;
    emit(const ArchivedClustersState.loading());
    try {
      final items = await _repository.listArchivedByOwnerId(ownerId);
      if (isClosed) return;
      emit(ArchivedClustersState.loaded(items));
    } catch (e) {
      if (isClosed) return;
      emit(ArchivedClustersState.error('$e'));
    }
  }
}

@freezed
class ArchivedClustersState with _$ArchivedClustersState {
  const factory ArchivedClustersState.initial() = _Initial;
  const factory ArchivedClustersState.loading() = _Loading;
  const factory ArchivedClustersState.loaded(List<ClusterModel> items) = _Loaded;
  const factory ArchivedClustersState.error(String message) = _Error;
}

