import 'package:clover/feature/_catalog_/marker_tags/data/catalog/marker_tags_catalog.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MarkerTagsRepository {
  /// Весь справочник тегов для UI (из enum, без sync/cache).
  Future<List<MarkerTagModel>> listAll();

  /// Теги, привязанные к маркеру (`marker_tag_links`).
  Future<List<MarkerTagModel>> listForMarker(String markerId);

  /// UUID тегов в БД по ключам enum (`marker_tags.key`).
  Future<List<String>> resolveTagIds(Set<String> tagKeys);

  /// [tagKeys] — ключи `marker_tags.key` (как в enum).
  Future<void> setForMarker({required String markerId, required Set<String> tagKeys});

  /// [tagKeys] — ключи `marker_tags.key` (как в enum).
  Future<void> setForPost({required String postId, required Set<String> tagKeys});
}

@LazySingleton(as: MarkerTagsRepository)
class MarkerTagsRepositoryImpl implements MarkerTagsRepository {
  MarkerTagsRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _tagColumns = '''
id,
key,
group_key,
created_at
''';

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  String? get _uid => _client.auth.currentUser?.id;

  void _requireSession() {
    if (_uid == null) {
      throw StateError('Нет сессии: войдите в аккаунт');
    }
  }

  MarkerTagModel _parseTagRow(Map<String, dynamic> json) {
    return MarkerTagModel.fromJson(json);
  }

  @override
  Future<List<MarkerTagModel>> listAll() async {
    return MarkerTagsCatalog.all;
  }

  @override
  Future<List<MarkerTagModel>> listForMarker(String markerId) async {
    _requireSession();
    final trimmed = markerId.trim();
    if (trimmed.isEmpty) return const [];

    final data = await _client
        .from('marker_tag_links')
        .select('marker_tags($_tagColumns)')
        .eq('marker_id', trimmed);

    final list = data as List<dynamic>;
    final tags = <MarkerTagModel>[];

    for (final row in list) {
      final map = Map<String, dynamic>.from(row as Map);
      final nested = map['marker_tags'];
      if (nested is! Map) continue;
      tags.add(_parseTagRow(Map<String, dynamic>.from(nested)));
    }

    tags.sort((a, b) {
      final byGroup = MarkerTagGroupKey.compare(a.groupKeyEnum, b.groupKeyEnum);
      if (byGroup != 0) return byGroup;
      return a.labelRu.compareTo(b.labelRu);
    });

    return tags;
  }

  @override
  Future<List<String>> resolveTagIds(Set<String> tagKeys) async {
    final ids = await _resolveTagIds(tagKeys);
    return ids.toList(growable: false)..sort();
  }

  @override
  Future<void> setForMarker({required String markerId, required Set<String> tagKeys}) async {
    _requireSession();
    final trimmedMarkerId = markerId.trim();
    if (trimmedMarkerId.isEmpty) {
      throw ArgumentError('Пустой markerId');
    }

    final resolvedIds = await _resolveTagIds(tagKeys);

    await _client.from('marker_tag_links').delete().eq('marker_id', trimmedMarkerId);

    if (resolvedIds.isEmpty) return;

    await _client.from('marker_tag_links').insert(
      resolvedIds
          .map((tagId) => {'marker_id': trimmedMarkerId, 'tag_id': tagId})
          .toList(growable: false),
    );
  }

  @override
  Future<void> setForPost({required String postId, required Set<String> tagKeys}) async {
    _requireSession();
    final trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      throw ArgumentError('Пустой postId');
    }

    final resolvedIds = await _resolveTagIds(tagKeys);

    await _client.from('post_tag_links').delete().eq('post_id', trimmedPostId);

    if (resolvedIds.isEmpty) return;

    await _client.from('post_tag_links').insert(
      resolvedIds
          .map((tagId) => {'post_id': trimmedPostId, 'tag_id': tagId})
          .toList(growable: false),
    );
  }

  Future<Set<String>> _resolveTagIds(Set<String> keysOrIds) async {
    final normalized = keysOrIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (normalized.isEmpty) return const {};

    final keys = <String>[];
    final ids = <String>{};

    for (final value in normalized) {
      if (_uuidPattern.hasMatch(value)) {
        ids.add(value);
      } else {
        keys.add(value);
      }
    }

    if (keys.isEmpty) return ids;

    final data = await _client.from('marker_tags').select('id, key').inFilter('key', keys);

    for (final row in data as List<dynamic>) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id']?.toString().trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }

    return ids;
  }
}
