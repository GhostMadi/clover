import 'package:clover/feature/_booking_/booking_client/data/models/client_booking_slot.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/booking_settings/data/repository/booking_schedule_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_error.dart';
import 'package:clover/feature/_booking_/shared/data/booking_json.dart';
import 'package:clover/feature/_booking_/shared/data/models/client_booking_slot_status.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingAvailabilityResult {
  const BookingAvailabilityResult({
    this.dayUnavailableReason,
    required this.slots,
    this.workStart,
    this.workEnd,
    this.slotStepMinutes = 30,
  });

  final String? dayUnavailableReason;
  final List<ClientBookingSlot> slots;
  final String? workStart;
  final String? workEnd;
  final int slotStepMinutes;
}

@lazySingleton
class BookingClientRepository {
  BookingClientRepository(
    this._client,
    this._servicesRepository,
    this._scheduleRepository,
  );

  final SupabaseClient _client;
  final BookingServicesRepository _servicesRepository;
  final BookingScheduleRepository _scheduleRepository;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<List<BookingServiceWithStaff>> loadCatalog(String hostId) =>
      _servicesRepository.listHostCatalog(hostId);

  Future<BookingScheduleSettings> loadHostSchedule(String hostId) =>
      _scheduleRepository.getSettings(hostId: hostId);

  Future<BookingAvailabilityResult> loadAvailability({
    required String hostId,
    required String serviceId,
    required String staffId,
    required DateTime day,
    String? excludeBookingId,
  }) async {
    return _guard(() async {
      final params = <String, dynamic>{
        'p_host_id': hostId,
        'p_service_id': serviceId,
        'p_staff_id': staffId,
        'p_day': _dateKey(day),
      };
      final excludedId = excludeBookingId?.trim();
      if (excludedId != null && excludedId.isNotEmpty) {
        params['p_exclude_booking_id'] = excludedId;
      }
      final res = await _client.rpc('get_booking_availability', params: params);

      if (res is! Map) {
        return const BookingAvailabilityResult(slots: []);
      }

      final map = Map<String, dynamic>.from(res);
      final slotsRaw = map['slots'];
      final slots = <ClientBookingSlot>[];

      if (slotsRaw is List) {
        for (final item in slotsRaw) {
          if (item is! Map) continue;
          final slotMap = Map<String, dynamic>.from(item);
          final startsAt = BookingJson.asDateTime(slotMap['starts_at']);
          if (startsAt == null) continue;
          slots.add(
            ClientBookingSlot(
              startsAt: startsAt.toLocal(),
              status: ClientBookingSlotStatus.fromApiOrAvailable(
                slotMap['status']?.toString(),
              ),
              conflictLabel: BookingJson.asString(slotMap['conflict_label']),
            ),
          );
        }
      }

      return BookingAvailabilityResult(
        dayUnavailableReason: BookingJson.asString(
          map['day_unavailable_reason'],
        ),
        slots: slots,
        workStart: BookingJson.asString(map['work_start']),
        workEnd: BookingJson.asString(map['work_end']),
        slotStepMinutes: BookingJson.asInt(
          map['slot_step_minutes'],
          fallback: 30,
        ),
      );
    });
  }

  Future<String> createBooking({
    required String hostId,
    required String serviceId,
    required String staffId,
    required DateTime startsAt,
    String? clientNotes,
    int participantsCount = 1,
    bool useBonuses = true,
  }) async {
    return _guard(() async {
      final id = await _client.rpc(
        'create_booking',
        params: {
          'p_host_id': hostId,
          'p_service_id': serviceId,
          'p_staff_id': staffId,
          'p_starts_at': startsAt.toUtc().toIso8601String(),
          'p_participants_count': participantsCount,
          'p_client_notes': clientNotes,
          'p_use_bonuses': useBonuses,
        },
      );
      return id?.toString() ?? '';
    });
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<int> getMyBonusBalanceAtHost(String hostId) async {
    final id = hostId.trim();
    if (id.isEmpty) return 0;

    return _guard(() async {
      final res = await _client.rpc(
        'get_my_bonus_balance_at_host',
        params: {'p_host_id': id},
      );
      if (res is int) return res;
      if (res is num) return res.toInt();
      return int.tryParse(res?.toString() ?? '') ?? 0;
    });
  }
}
