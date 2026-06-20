import 'package:clover/feature/work/data/models/work_relation_model.dart';
import 'package:clover/feature/work/data/models/work_relation_status.dart';
import 'package:clover/feature/work/data/models/work_relation_type.dart';
import 'package:clover/feature/work/data/repository/work_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'worker_work_cubit.freezed.dart';

@injectable
class WorkerWorkCubit extends Cubit<WorkerWorkState> {
  WorkerWorkCubit(this._repository) : super(const WorkerWorkState.initial());

  final WorkRepository _repository;

  String? get _uid => Supabase.instance.client.auth.currentUser?.id.trim();

  Future<void> load() async {
    emit(const WorkerWorkState.loading());
    try {
      final relations = await _repository.listMyRelations();
      if (isClosed) return;
      emit(WorkerWorkState.loaded(relations: relations));
    } catch (e) {
      if (isClosed) return;
      emit(WorkerWorkState.error('$e'));
    }
  }

  Future<void> refresh() async {
    final hadData = state.mapOrNull(loaded: (_) => true) ?? false;
    if (!hadData) {
      await load();
      return;
    }
    try {
      final relations = await _repository.listMyRelations();
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      emit(WorkerWorkState.loaded(
        relations: relations,
        mainTabIndex: loaded?.mainTabIndex ?? 0,
      ));
    } catch (_) {}
  }

  void setMainTab(int index) {
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded == null) return;
    emit(loaded.copyWith(mainTabIndex: index.clamp(0, 1)));
  }

  Set<String> get inviteExcludePeerIds {
    final relations = state.mapOrNull(loaded: (s) => s.relations);
    if (relations == null) return const {};
    return WorkRelationModel.peerIdsWithOpenRelation(relations);
  }

  Future<void> apply(String targetUserId) async {
    await _repository.requestRelation(targetUserId, WorkRelationType.join);
    await refresh();
    final loaded = state.mapOrNull(loaded: (s) => s);
    if (loaded != null && !isClosed) {
      emit(loaded.copyWith(mainTabIndex: 1));
    }
  }

  Future<void> accept(WorkRelationModel relation) async {
    await _repository.acceptRelation(relation.id);
    await refresh();
  }

  Future<void> decline(WorkRelationModel relation) async {
    await _repository.rejectRelation(relation.id);
    await refresh();
  }

  Future<void> withdraw(WorkRelationModel relation) async {
    await _repository.withdrawRelation(relation.id);
    await refresh();
  }

  List<WorkRelationModel> employersFor(WorkerWorkLoaded state) {
    final uid = _uid;
    if (uid == null) return const [];
    return state.relations.where((r) => WorkRelationModel.isActiveEmployer(r, uid)).toList();
  }

  List<WorkRelationModel> incomingRequestsFor(WorkerWorkLoaded state) {
    return state.relations
        .where((r) => r.isIncoming && r.status == WorkRelationStatus.pending)
        .toList();
  }

  List<WorkRelationModel> outgoingRequestsFor(WorkerWorkLoaded state) {
    return state.relations
        .where((r) => !r.isIncoming && r.status != WorkRelationStatus.terminated)
        .toList();
  }
}

@freezed
class WorkerWorkState with _$WorkerWorkState {
  const factory WorkerWorkState.initial() = _Initial;
  const factory WorkerWorkState.loading() = _Loading;
  const factory WorkerWorkState.loaded({
    required List<WorkRelationModel> relations,
    @Default(0) int mainTabIndex,
  }) = WorkerWorkLoaded;
  const factory WorkerWorkState.error(String message) = _Error;
}
