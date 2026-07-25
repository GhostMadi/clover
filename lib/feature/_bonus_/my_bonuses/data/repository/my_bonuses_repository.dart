import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_accounts_page.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MyBonusesRepository {
  Future<BonusAccountsPage> listMyAccounts({int limit = 50});
}

@LazySingleton(as: MyBonusesRepository)
class MyBonusesRepositoryImpl implements MyBonusesRepository {
  MyBonusesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<BonusAccountsPage> listMyAccounts({int limit = 50}) async {
    final res = await _client.rpc('list_my_bonus_accounts', params: {'p_limit': limit});
    final items = _parseRows(res);
    return BonusAccountsPage(items: items);
  }

  static List<BonusAccountItem> _parseRows(dynamic res) {
    if (res is! List) return const [];

    final items = <BonusAccountItem>[];
    for (final row in res) {
      final item = _parseRow(row);
      if (item != null) items.add(item);
    }
    return items;
  }

  static BonusAccountItem? _parseRow(dynamic row) {
    if (row is! Map) return null;
    final map = Map<String, dynamic>.from(row);

    final hostId = (map['host_id'] as String?)?.trim();
    if (hostId == null || hostId.isEmpty) return null;

    final balance = _asInt(map['balance']);
    final host = map['host'];
    if (host is! Map) {
      return BonusAccountItem(hostId: hostId, hostDisplayName: 'Аккаунт', balance: balance);
    }

    final hostMap = Map<String, dynamic>.from(host);
    final displayName = (hostMap['full_name'] as String?)?.trim();
    return BonusAccountItem(
      hostId: hostId,
      hostDisplayName: displayName == null || displayName.isEmpty ? 'Аккаунт' : displayName,
      hostUsername: hostMap['username'] as String?,
      avatarUrl: hostMap['avatar_url'] as String?,
      balance: balance,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
