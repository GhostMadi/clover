import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';
import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_page_result.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BonusHistoryRepository {
  Future<BonusHistoryPageResult> listHistory({
    required String hostId,
    int limit = 50,
    BonusHistoryEntry? cursorItem,
  });
}

@LazySingleton(as: BonusHistoryRepository)
class BonusHistoryRepositoryImpl implements BonusHistoryRepository {
  BonusHistoryRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<BonusHistoryPageResult> listHistory({
    required String hostId,
    int limit = 50,
    BonusHistoryEntry? cursorItem,
  }) async {
    final id = hostId.trim();
    if (id.isEmpty) {
      return const BonusHistoryPageResult(balance: 0, items: [], hasMore: false);
    }

    final params = <String, dynamic>{
      'p_host_id': id,
      'p_limit': limit,
    };
    if (cursorItem != null) {
      params['p_cursor_created_at'] = cursorItem.occurredAt.toUtc().toIso8601String();
      params['p_cursor_id'] = cursorItem.id;
    }

    final res = await _client.rpc('list_bonus_ledger_cursor', params: params);
    if (res is! Map) {
      return const BonusHistoryPageResult(balance: 0, items: [], hasMore: false);
    }

    final map = Map<String, dynamic>.from(res);
    return BonusHistoryPageResult(
      balance: _asInt(map['balance']),
      items: _parseItems(map['items']),
      hasMore: map['has_more'] == true,
    );
  }

  static List<BonusHistoryEntry> _parseItems(dynamic raw) {
    if (raw is! List) return const [];

    final items = <BonusHistoryEntry>[];
    for (final row in raw) {
      final item = _parseEntry(row);
      if (item != null) items.add(item);
    }
    return items;
  }

  static BonusHistoryEntry? _parseEntry(dynamic row) {
    if (row is! Map) return null;
    final map = Map<String, dynamic>.from(row);

    final id = (map['id'] as String?)?.trim();
    final title = (map['title'] as String?)?.trim();
    final createdRaw = map['created_at']?.toString();
    if (id == null || id.isEmpty || title == null || title.isEmpty || createdRaw == null) {
      return null;
    }

    final kind = (map['kind'] as String?)?.trim() ?? 'earn';
    final isCredit = kind == 'earn' || kind == 'adjust';

    return BonusHistoryEntry(
      id: id,
      title: title,
      subtitle: (map['subtitle'] as String?)?.trim() ?? '',
      amount: _asInt(map['amount']),
      occurredAt: DateTime.parse(createdRaw),
      isCredit: isCredit,
      source: (map['source'] as String?)?.trim(),
      sourceId: (map['source_id'] as String?)?.trim(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
