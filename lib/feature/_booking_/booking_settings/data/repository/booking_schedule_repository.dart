import 'package:clover/feature/_booking_/booking_settings/data/models/booking_executor_absence.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_json.dart';
import 'package:clover/feature/_booking_/shared/data/models/booking_horizon_kind.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@lazySingleton
class BookingScheduleRepository {
  BookingScheduleRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id.trim();

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<BookingScheduleSettings> getSettings({String? hostId}) async {
    final id = (hostId ?? _uid)?.trim();
    if (id == null || id.isEmpty) return BookingScheduleSettings.defaults();

    return _guard(() async {
      final settingsRow = await _client
          .from('booking_schedule_settings')
          .select()
          .eq('host_id', id)
          .maybeSingle();

      final absencesRes = await _client
          .from('booking_staff_absences')
          .select()
          .eq('host_id', id)
          .order('start_date');

      final absences = [
        for (final row in absencesRes) _mapAbsence(Map<String, dynamic>.from(row)),
      ];

      if (settingsRow == null) {
        return BookingScheduleSettings.defaults().copyWith(executorAbsences: absences);
      }

      return _mapSettings(Map<String, dynamic>.from(settingsRow), absences: absences);
    });
  }

  Future<BookingScheduleSettings> saveMySettings(BookingScheduleSettings settings) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    return _guard(() async {
      final start = (settings.workStartHour, settings.workStartMinute);
      final end = (settings.workEndHour, settings.workEndMinute);

      await _client.from('booking_schedule_settings').upsert({
        'host_id': uid,
        'rest_weekdays': settings.restWeekdays.toList(),
        'horizon_kind': settings.horizonKind.dbValue,
        'max_booking_days_ahead': settings.maxBookingDaysAhead,
        'max_booking_until_date': settings.horizonKind == BookingHorizonKind.untilDate
            ? settings.maxBookingUntilDate?.toIso8601String().substring(0, 10)
            : null,
        'default_work_start_time':
            '${start.$1.toString().padLeft(2, '0')}:${start.$2.toString().padLeft(2, '0')}:00',
        'default_work_end_time':
            '${end.$1.toString().padLeft(2, '0')}:${end.$2.toString().padLeft(2, '0')}:00',
        'client_cancel_hours_before': settings.clientCancelHoursBefore,
        'auto_close_hours_after_visit': settings.autoCloseHoursAfterVisit,
        'auto_close_target': 'no_show',
      });

      await _client.rpc(
        'replace_booking_staff_absences',
        params: {
          'p_absences': [
            for (final absence in settings.executorAbsences)
              {
                'staff_id': absence.executorId,
                'start_date': _dateKey(absence.startDay),
                'end_date': _dateKey(absence.endDay),
                if (absence.note != null && absence.note!.trim().isNotEmpty) 'note': absence.note!.trim(),
              },
          ],
        },
      );

      return getSettings(hostId: uid);
    });
  }

  BookingScheduleSettings _mapSettings(
    Map<String, dynamic> row, {
    required List<BookingExecutorAbsence> absences,
  }) {
    final start = BookingJson.parseTime(row['default_work_start_time']);
    final end = BookingJson.parseTime(row['default_work_end_time']);
    final horizon = BookingHorizonKind.fromDbOrDefault(row['horizon_kind']?.toString());
    final untilRaw = BookingJson.asString(row['max_booking_until_date']);

    return BookingScheduleSettings(
      restWeekdays: BookingJson.asIntList(row['rest_weekdays']).toSet(),
      horizonKind: horizon == BookingHorizonKind.untilDate
          ? BookingHorizonKind.untilDate
          : BookingHorizonKind.daysAhead,
      maxBookingDaysAhead: BookingJson.asInt(row['max_booking_days_ahead'], fallback: 14),
      maxBookingUntilDate: untilRaw == null ? null : DateTime.tryParse(untilRaw),
      workStartHour: start.$1,
      workStartMinute: start.$2,
      workEndHour: end.$1,
      workEndMinute: end.$2,
      executorAbsences: absences,
      clientCancelHoursBefore: BookingJson.asInt(row['client_cancel_hours_before'], fallback: 0),
      autoCloseHoursAfterVisit: BookingJson.asInt(row['auto_close_hours_after_visit'], fallback: 0),
    );
  }

  BookingExecutorAbsence _mapAbsence(Map<String, dynamic> row) {
    final startRaw = BookingJson.asString(row['start_date']);
    final endRaw = BookingJson.asString(row['end_date']);
    return BookingExecutorAbsence(
      id: row['id']?.toString() ?? '',
      executorId: row['staff_id']?.toString() ?? '',
      startDay: DateTime.tryParse(startRaw ?? '') ?? DateTime.now(),
      endDay: DateTime.tryParse(endRaw ?? '') ?? DateTime.now(),
      note: BookingJson.asString(row['note']),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
