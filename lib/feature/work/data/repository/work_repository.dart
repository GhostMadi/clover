import 'package:clover/feature/work/data/models/work_member.dart';
import 'package:clover/feature/work/data/models/work_relation_error.dart';
import 'package:clover/feature/work/data/models/work_relation_model.dart';
import 'package:clover/feature/work/data/models/work_relation_status.dart';
import 'package:clover/feature/work/data/models/work_relation_type.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class WorkRepository {
  Future<List<WorkRelationModel>> listMyRelations();

  Future<List<WorkMember>> searchProfiles(String query, {required WorkRelationType action});

  Future<void> requestRelation(String targetUserId, WorkRelationType action);

  Future<void> acceptRelation(String relationId);

  Future<void> rejectRelation(String relationId);

  Future<void> withdrawRelation(String relationId);

  Future<void> terminateRelation(String relationId);
}

@LazySingleton(as: WorkRepository)
class WorkRepositoryImpl implements WorkRepository {
  WorkRepositoryImpl(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id.trim();

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw WorkRelationError.from(e);
    }
  }

  @override
  Future<List<WorkRelationModel>> listMyRelations() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      final res = await _client.rpc('list_my_relations_enriched');
      if (res is! List) return const [];

      return [
        for (final raw in res)
          if (raw is Map)
            WorkRelationModel.fromEnrichedRow(Map<String, dynamic>.from(raw), currentUserId: uid),
      ];
    });
  }

  @override
  Future<List<WorkMember>> searchProfiles(String query, {required WorkRelationType action}) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      final q = query.trim();
      var builder = _client.from('profiles').select('id, username, full_name, avatar_url');

      builder = builder.neq('id', uid);

      if (q.isNotEmpty) {
        final pattern = '%$q%';
        builder = builder.or('username.ilike.$pattern,full_name.ilike.$pattern');
      }

      final res = await builder.order('username').limit(20);

      return [
        for (final raw in res)
          WorkMember(
            id: raw['id']?.toString().trim() ?? '',
            username: raw['username']?.toString() ?? 'noName',
            avatarUrl: raw['avatar_url']?.toString(),
            displayName: raw['full_name']?.toString(),
          ),
      ].where((m) => m.id.isNotEmpty).toList();
    });
  }

  @override
  Future<void> requestRelation(String targetUserId, WorkRelationType action) async {
    final id = targetUserId.trim();
    if (id.isEmpty) throw WorkRelationError('Не выбран пользователь');

    return _guard(() => _client.rpc('request_relation', params: {
      'p_target_id': id,
      'p_action': action.dbValue,
    }));
  }

  @override
  Future<void> acceptRelation(String relationId) async {
    await _updateStatus(relationId, WorkRelationStatus.active);
  }

  @override
  Future<void> rejectRelation(String relationId) async {
    await _updateStatus(relationId, WorkRelationStatus.rejected);
  }

  @override
  Future<void> withdrawRelation(String relationId) async {
    final id = relationId.trim();
    if (id.isEmpty) throw WorkRelationError('Заявка не найдена');
    return _guard(() => _client.rpc('withdraw_relation', params: {'p_relation_id': id}));
  }

  @override
  Future<void> terminateRelation(String relationId) async {
    await _updateStatus(relationId, WorkRelationStatus.terminated);
  }

  Future<void> _updateStatus(String relationId, WorkRelationStatus status) async {
    final id = relationId.trim();
    if (id.isEmpty) throw WorkRelationError('Заявка не найдена');
    return _guard(() => _client.rpc('update_relation_status', params: {
      'p_relation_id': id,
      'p_new_status': status.dbValue,
    }));
  }
}
