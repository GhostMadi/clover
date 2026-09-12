import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingBlockedSlot {
  const BookingBlockedSlot({
    required this.id,
    required this.staffId,
    required this.startsAt,
    required this.endsAt,
    this.reason,
  });

  final String id;
  final String staffId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
}

class BookingStaffDaySchedule {
  const BookingStaffDaySchedule({
    required this.staffId,
    required this.weekday,
    required this.isWorking,
    this.workStartHour,
    this.workEndHour,
  });

  final String staffId;
  final int weekday; // ISO 1–7
  final bool isWorking;
  final int? workStartHour;
  final int? workEndHour;
}

@lazySingleton
class BookingOpsRepository {
  BookingOpsRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<List<BookingBlockedSlot>> listBlockedSlots({
    required DateTime from,
    required DateTime to,
    required String pointId,
  }) {
    return _guard(() async {
      final uid = _client.auth.currentUser?.id;
      final pid = pointId.trim();
      if (uid == null || pid.isEmpty) return const [];
      final res = await _client
          .from('booking_blocked_slots')
          .select('id, staff_id, starts_at, ends_at, reason')
          .eq('host_id', uid)
          .eq('point_id', pid)
          .gte('starts_at', from.toUtc().toIso8601String())
          .lte('starts_at', to.toUtc().toIso8601String())
          .order('starts_at');
      return [
        for (final raw in res as List)
          if (raw is Map)
            BookingBlockedSlot(
              id: raw['id']?.toString() ?? '',
              staffId: raw['staff_id']?.toString() ?? '',
              startsAt: DateTime.tryParse(raw['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
              endsAt: DateTime.tryParse(raw['ends_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
              reason: raw['reason']?.toString(),
            ),
      ];
    });
  }

  Future<void> createBlockedSlot({
    required String pointId,
    required String staffId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  }) {
    return _guard(() async {
      final uid = _client.auth.currentUser?.id;
      final pid = pointId.trim();
      if (uid == null) throw const BookingException(BookingErrorCode.unknown, 'Войдите в аккаунт');
      if (pid.isEmpty) throw const BookingException(BookingErrorCode.unknown, 'Нет точки');
      await _client.from('booking_blocked_slots').insert({
        'host_id': uid,
        'point_id': pid,
        'staff_id': staffId,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
    });
  }

  Future<void> deleteBlockedSlot(String id) {
    return _guard(() async {
      await _client.from('booking_blocked_slots').delete().eq('id', id);
    });
  }

  Future<List<BookingStaffDaySchedule>> listStaffSchedule(String staffId) {
    return _guard(() async {
      final res = await _client
          .from('booking_staff_schedule')
          .select('staff_id, weekday, is_working, work_start_time, work_end_time')
          .eq('staff_id', staffId);
      return [
        for (final raw in res as List)
          if (raw is Map)
            BookingStaffDaySchedule(
              staffId: raw['staff_id']?.toString() ?? staffId,
              weekday: (raw['weekday'] as num?)?.toInt() ?? 1,
              isWorking: raw['is_working'] as bool? ?? true,
              workStartHour: _hourFromTime(raw['work_start_time']?.toString()),
              workEndHour: _hourFromTime(raw['work_end_time']?.toString()),
            ),
      ];
    });
  }

  Future<void> upsertStaffDay({
    required String staffId,
    required int weekday,
    required bool isWorking,
    int? workStartHour,
    int? workEndHour,
  }) {
    return _guard(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const BookingException(BookingErrorCode.unknown, 'Войдите в аккаунт');
      await _client.from('booking_staff_schedule').upsert(
        {
          'host_id': uid,
          'staff_id': staffId,
          'weekday': weekday,
          'is_working': isWorking,
          'work_start_time': isWorking && workStartHour != null
              ? '${workStartHour.toString().padLeft(2, '0')}:00:00'
              : null,
          'work_end_time': isWorking && workEndHour != null
              ? '${workEndHour.toString().padLeft(2, '0')}:00:00'
              : null,
        },
        onConflict: 'staff_id,weekday',
      );
    });
  }

  static int? _hourFromTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.isEmpty) return null;
    return int.tryParse(parts.first);
  }
}
