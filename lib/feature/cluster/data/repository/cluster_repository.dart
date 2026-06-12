import 'dart:developer';
import 'dart:typed_data';

import 'package:clover/feature/cluster/data/models/cluster_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ClusterRepository {
  /// Неархивные кластеры владельца, по [sort_order] (как в БД).
  Future<List<ClusterModel>> listActiveByOwnerId(String ownerId);

  /// Архивные кластеры владельца, по updated_at desc (последние изменения сверху).
  Future<List<ClusterModel>> listArchivedByOwnerId(String ownerId);

  /// Создание кластера текущим пользователем; при [coverBytes] — загрузка в Storage, затем [cover_url].
  ///
  /// Бакет `cluster_covers` должен существовать в проекте Supabase (публичное чтение, загрузка для authenticated).
  Future<ClusterModel> createCluster({required String title, String? subtitle, Uint8List? coverBytes});

  /// Обновить обложку: при [coverBytes] — overwrite по фиксированному path; при `null` — удалить объект и очистить `cover_url`.
  Future<ClusterModel> updateClusterCover({required String clusterId, Uint8List? coverBytes});

  /// Удалить кластер и его обложку в Storage (без Edge).
  ///
  /// Важно: чтобы не «забивать» Storage, удаляем объект **до** удаления строки в БД.
  Future<void> deleteCluster({required String clusterId});

  /// Архивировать кластер (is_archived = true). Для восстановления можно будет сделать отдельный метод.
  Future<ClusterModel> archiveCluster({required String clusterId});

  /// Разархивировать кластер (is_archived = false).
  Future<ClusterModel> unarchiveCluster({required String clusterId});
}

@LazySingleton(as: ClusterRepository)
class ClusterRepositoryImpl implements ClusterRepository {
  ClusterRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _bucketClusterCovers = 'cluster_covers';

  @override
  Future<List<ClusterModel>> listActiveByOwnerId(String ownerId) async {
    final data = await _client
        .from('clusters')
        .select()
        .eq('owner_id', ownerId)
        .eq('is_archived', false)
        .order('sort_order', ascending: true);

    final list = data as List<dynamic>;
    
    return list.map((e) => ClusterModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<List<ClusterModel>> listArchivedByOwnerId(String ownerId) async {
    final data = await _client
        .from('clusters')
        .select()
        .eq('owner_id', ownerId)
        .eq('is_archived', true)
        .order('updated_at', ascending: false);

    final list = data as List<dynamic>;
    return list.map((e) => ClusterModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<ClusterModel> createCluster({required String title, String? subtitle, Uint8List? coverBytes}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }

    final t = title.trim();
    if (t.isEmpty) {
      throw ArgumentError('Пустое название');
    }

    String? sub;
    final rawSub = subtitle?.trim();
    if (rawSub != null && rawSub.isNotEmpty) {
      sub = rawSub;
    }

    final maxRow = await _client
        .from('clusters')
        .select('sort_order')
        .eq('owner_id', uid)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();

    final nextSort = (maxRow != null ? (maxRow['sort_order'] as num).toInt() : -1) + 1;

    final insertRow = <String, dynamic>{
      'owner_id': uid,
      'title': t,
      'sort_order': nextSort,
      if (sub != null) 'subtitle': sub,
    };

    final inserted = await _client.from('clusters').insert(insertRow).select().single();

    var cluster = ClusterModel.fromJson(Map<String, dynamic>.from(inserted));

    if (coverBytes != null && coverBytes.isNotEmpty) {
      final id = cluster.id;
      cluster = await updateClusterCover(clusterId: id, coverBytes: coverBytes);
    }

    return cluster;
  }

  @override
  Future<ClusterModel> updateClusterCover({required String clusterId, Uint8List? coverBytes}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
    final id = clusterId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Пустой clusterId');
    }

    final path = _clusterCoverPath(ownerId: uid, clusterId: id);

    if (coverBytes == null || coverBytes.isEmpty) {
      // Cleanup object first to avoid stale files.
      await _client.storage.from(_bucketClusterCovers).remove([path]);
      final updated = await _client
          .from('clusters')
          .update({'cover_url': null})
          .eq('id', id)
          .select()
          .single();
      return ClusterModel.fromJson(Map<String, dynamic>.from(updated));
    }

    final compressed = await FlutterImageCompress.compressWithList(coverBytes);
    await _client.storage
        .from(_bucketClusterCovers)
        .uploadBinary(
          path,
          compressed,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final coverUrl = _publicUrlWithVersion(path: path);
    final updated = await _client
        .from('clusters')
        .update({'cover_url': coverUrl})
        .eq('id', id)
        .select()
        .single();
    return ClusterModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> deleteCluster({required String clusterId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
    final id = clusterId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Пустой clusterId');
    }

    final path = _clusterCoverPath(ownerId: uid, clusterId: id);
    // Try delete cover first to prevent Storage bloat.
    // If object doesn't exist, Storage API can throw; ignore only 404-like errors if they bubble up as generic.
    try {
      await _client.storage.from(_bucketClusterCovers).remove([path]);
    } catch (_) {
      // Без Edge нет 100% гарантии; но лучше не удалять строку, если Storage отвалился.
      rethrow;
    }

    await _client.from('clusters').delete().eq('id', id);
  }

  @override
  Future<ClusterModel> archiveCluster({required String clusterId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
    final id = clusterId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Пустой clusterId');
    }

    final updated = await _client
        .from('clusters')
        .update({'is_archived': true})
        .eq('id', id)
        .select()
        .single();
    return ClusterModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<ClusterModel> unarchiveCluster({required String clusterId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
    final id = clusterId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Пустой clusterId');
    }

    final updated = await _client
        .from('clusters')
        .update({'is_archived': false})
        .eq('id', id)
        .select()
        .single();
    return ClusterModel.fromJson(Map<String, dynamic>.from(updated));
  }

  String _clusterCoverPath({required String ownerId, required String clusterId}) {
    return '$ownerId/$clusterId/cover.jpg';
  }

  String _publicUrlWithVersion({required String path}) {
    final base = _client.storage.from(_bucketClusterCovers).getPublicUrl(path);
    final v = DateTime.now().millisecondsSinceEpoch;
    return '$base?v=$v';
  }
}
