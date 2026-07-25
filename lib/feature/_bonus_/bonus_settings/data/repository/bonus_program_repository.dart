import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BonusProgramRepository {
  Future<BonusProgramStatus> updateMyProgramStatus(BonusProgramStatus status);
}

@LazySingleton(as: BonusProgramRepository)
class BonusProgramRepositoryImpl implements BonusProgramRepository {
  BonusProgramRepositoryImpl(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id.trim();

  @override
  Future<BonusProgramStatus> updateMyProgramStatus(BonusProgramStatus status) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BonusProgramException('Необходима авторизация');
    }

    await _client.from('profiles').update({'bonus_program_status': status.dbValue}).eq('id', uid);

    return status;
  }
}

class BonusProgramException implements Exception {
  const BonusProgramException(this.message);

  final String message;

  @override
  String toString() => message;
}
