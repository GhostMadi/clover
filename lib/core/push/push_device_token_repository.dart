import 'package:clover/core/push/push_device_platform.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class PushDeviceTokenRepository {
  PushDeviceTokenRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'push_device_tokens';

  Future<void> upsert({
    required String userId,
    required String token,
    required PushDevicePlatform platform,
  }) async {
    await _client.from(_table).upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': platform.storageValue,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,token',
    );
  }

  Future<void> deleteToken(String token) async {
    await _client.from(_table).delete().eq('token', token);
  }
}
