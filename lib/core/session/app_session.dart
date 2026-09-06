import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Текущий uid сессии без протаскивания [SupabaseClient] в cubit’ы «ради id».
@lazySingleton
class AppSession {
  AppSession(this._client);

  final SupabaseClient _client;

  String? get userId {
    final id = _client.auth.currentUser?.id.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
