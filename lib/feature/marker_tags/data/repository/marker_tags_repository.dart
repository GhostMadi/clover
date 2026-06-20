import 'package:clover/feature/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MarkerTagsRepository {
  /// Весь справочник `marker_tags` (публичное чтение).
  Future<List<MarkerTagModel>> listAll();

  /// Теги, привязанные к маркеру (`marker_tag_links`).
  Future<List<MarkerTagModel>> listForMarker(String markerId);

  /// Заменить набор тегов маркера (только владелец маркера по RLS).
  Future<void> setForMarker({required String markerId, required Set<String> tagIds});
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
    final data = await _client.from('marker_tags').select(_tagColumns).order('group_key').order('key');

    final list = data as List<dynamic>;
    return list
        .map((e) => _parseTagRow(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
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
  Future<void> setForMarker({required String markerId, required Set<String> tagIds}) async {
    _requireSession();
    final trimmedMarkerId = markerId.trim();
    if (trimmedMarkerId.isEmpty) {
      throw ArgumentError('Пустой markerId');
    }

    final normalizedIds = tagIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

    await _client.from('marker_tag_links').delete().eq('marker_id', trimmedMarkerId);

    if (normalizedIds.isEmpty) return;

    await _client.from('marker_tag_links').insert(
      normalizedIds
          .map((tagId) => {'marker_id': trimmedMarkerId, 'tag_id': tagId})
          .toList(growable: false),
    );
  }
}
