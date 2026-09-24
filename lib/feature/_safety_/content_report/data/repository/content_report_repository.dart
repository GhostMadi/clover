import 'package:clover/feature/_safety_/content_report/data/models/content_report_reason.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class ContentReportRepository {
  ContentReportRepository(this._client);

  final SupabaseClient _client;

  Future<void> reportContent({
    required String targetUserId,
    required ContentReportReason reason,
    String? postId,
    String? note,
  }) async {
    final target = targetUserId.trim();
    if (target.isEmpty) throw ArgumentError('targetUserId');

    await _client.rpc(
      'report_content',
      params: {
        'p_target_user': target,
        'p_reason': reason.apiKey,
        if (postId != null && postId.trim().isNotEmpty) 'p_post_id': postId.trim(),
        if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
      },
    );
  }
}
