import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/shared/data/booking_error.dart';
import 'package:clover/feature/booking/shared/data/booking_json.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingServiceWithStaff {
  const BookingServiceWithStaff({
    required this.service,
    required this.staff,
  });

  final BookingService service;
  final List<BookingServiceExecutor> staff;
}

abstract class BookingServicesRepository {
  Future<List<BookingService>> listMyServices();

  Future<List<BookingServiceWithStaff>> listHostCatalog(String hostId);

  Future<BookingService> createService(BookingServiceDraft draft, {List<String>? staffIds});

  Future<BookingService> updateService(String id, BookingServiceDraft draft, {List<String>? staffIds});

  Future<void> deactivateService(String id);
}

@LazySingleton(as: BookingServicesRepository)
class BookingServicesRepositoryImpl implements BookingServicesRepository {
  BookingServicesRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const _staffLinkSelect =
      'staff_id, booking_staff(id, display_name, username, profile_id, is_active)';

  static const _serviceSelect =
      'id, host_id, title, emoji_text, description, duration_minutes, buffer_after_minutes, '
      'price, max_participants, default_staff_id, is_active, sort_order';

  static const _myServiceSelect =
      'id, host_id, title, emoji_text, description, duration_minutes, buffer_after_minutes, '
      'price, max_participants, default_staff_id, is_active, sort_order, '
      'booking_service_staff($_staffLinkSelect)';

  static const _catalogSelect =
      'id, host_id, title, emoji_text, description, duration_minutes, buffer_after_minutes, '
      'price, max_participants, default_staff_id, is_active, sort_order, '
      'booking_service_staff($_staffLinkSelect)';

  String? get _uid => _client.auth.currentUser?.id.trim();

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  @override
  Future<List<BookingService>> listMyServices() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return const [];

    return _guard(() async {
      final res = await _client
          .from('booking_services')
          .select(_myServiceSelect)
          .eq('host_id', uid)
          .order('sort_order')
          .order('title');
      return [for (final row in res) _mapService(Map<String, dynamic>.from(row))];
    });
  }

  @override
  Future<List<BookingServiceWithStaff>> listHostCatalog(String hostId) async {
    final id = hostId.trim();
    if (id.isEmpty) return const [];

    return _guard(() async {
      final res = await _client
          .from('booking_services')
          .select(_catalogSelect)
          .eq('host_id', id)
          .eq('is_active', true)
          .order('sort_order')
          .order('title');

      return [
        for (final row in res)
          BookingServiceWithStaff(
            service: _mapService(Map<String, dynamic>.from(row)),
            staff: _mapLinkedStaff(row['booking_service_staff']),
          ),
      ];
    });
  }

  @override
  Future<BookingService> createService(BookingServiceDraft draft, {List<String>? staffIds}) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    return _guard(() async {
      final ids = staffIds ?? _staffIdsFromDraft(draft);
      final res = await _client
          .from('booking_services')
          .insert(_draftToRow(draft, hostId: uid, defaultStaffId: ids.firstOrNull))
          .select(_serviceSelect)
          .single();
      final service = _mapService(Map<String, dynamic>.from(res));
      await _syncStaffLinks(service.id, ids);
      return service.copyWith(executorIds: ids);
    });
  }

  @override
  Future<BookingService> updateService(
    String id,
    BookingServiceDraft draft, {
    List<String>? staffIds,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const BookingException(BookingErrorCode.notAuthenticated);
    }

    return _guard(() async {
      if (!draft.isActive) {
        await _client.rpc('deactivate_booking_service', params: {'p_service_id': id});
        final row = await _client.from('booking_services').select(_myServiceSelect).eq('id', id).single();
        return _mapService(Map<String, dynamic>.from(row));
      }

      final ids = staffIds ?? _staffIdsFromDraft(draft);
      final res = await _client
          .from('booking_services')
          .update(_draftToRow(draft, hostId: uid, defaultStaffId: ids.firstOrNull))
          .eq('id', id)
          .eq('host_id', uid)
          .select(_serviceSelect)
          .single();

      final service = _mapService(Map<String, dynamic>.from(res));
      await _syncStaffLinks(service.id, ids);
      return service.copyWith(executorIds: ids);
    });
  }

  @override
  Future<void> deactivateService(String id) async {
    return _guard(() async {
      await _client.rpc('deactivate_booking_service', params: {'p_service_id': id});
    });
  }

  List<String> _staffIdsFromDraft(BookingServiceDraft draft) {
    return [
      for (final pick in draft.executors)
        if (pick.staffId != null && pick.staffId!.trim().isNotEmpty) pick.staffId!.trim(),
    ];
  }

  Future<void> _syncStaffLinks(String serviceId, List<String> staffIds) async {
    await _client.from('booking_service_staff').delete().eq('service_id', serviceId);
    final ids = staffIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (ids.isEmpty) return;
    await _client.from('booking_service_staff').insert([
      for (final staffId in ids) {'service_id': serviceId, 'staff_id': staffId},
    ]);
  }

  Map<String, dynamic> _draftToRow(
    BookingServiceDraft draft, {
    required String hostId,
    String? defaultStaffId,
  }) {
    final desc = draft.description.trim();
    return {
      'host_id': hostId,
      'title': draft.title.trim(),
      'emoji_text': draft.emojiText.trim(),
      'duration_minutes': draft.durationMinutes,
      'buffer_after_minutes': draft.bufferAfterMinutes,
      'price': draft.price,
      'max_participants': draft.maxParticipants,
      'default_staff_id': defaultStaffId ?? draft.defaultExecutorStaffId,
      'is_active': draft.isActive,
      if (desc.isNotEmpty) 'description': desc,
    };
  }

  BookingService _mapService(Map<String, dynamic> row) {
    final links = row['booking_service_staff'];
    final executorIds = _executorIdsFromLinks(links);
    final defaultId = BookingJson.asString(row['default_staff_id']);

    return BookingService(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      durationMinutes: BookingJson.asInt(row['duration_minutes'], fallback: 30),
      emojiText: row['emoji_text']?.toString() ?? '💈',
      price: BookingJson.asDouble(row['price']),
      maxParticipants: BookingJson.asInt(row['max_participants'], fallback: 1),
      bufferAfterMinutes: BookingJson.asInt(row['buffer_after_minutes']),
      description: BookingJson.asString(row['description']),
      executorIds: executorIds.isNotEmpty
          ? executorIds
          : (defaultId == null ? const [] : [defaultId]),
      isActive: BookingJson.asBool(row['is_active'], fallback: true),
    );
  }

  List<String> _executorIdsFromLinks(dynamic raw) {
    if (raw is! List) return const [];
    final ids = <String>[];
    for (final link in raw) {
      if (link is! Map) continue;
      final staffId = link['staff_id']?.toString();
      if (staffId != null && staffId.isNotEmpty) {
        ids.add(staffId);
        continue;
      }
      final row = link['booking_staff'];
      if (row is Map) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  List<BookingServiceExecutor> _mapLinkedStaff(dynamic raw) {
    if (raw is! List) return const [];
    final staff = <BookingServiceExecutor>[];
    for (final link in raw) {
      if (link is! Map) continue;
      final row = link['booking_staff'];
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      if (!BookingJson.asBool(map['is_active'], fallback: true)) continue;
      staff.add(
        BookingServiceExecutor(
          id: map['id']?.toString() ?? '',
          displayName: map['display_name']?.toString() ?? '',
          username: map['username']?.toString() ?? '',
          profileId: map['profile_id']?.toString(),
        ),
      );
    }
    return staff;
  }
}
