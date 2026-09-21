import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_host.dart';
import 'package:clover/feature/_booking_/booking_calendar/data/models/booking_calendar_item.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
import 'package:clover/feature/_booking_/booking_points/data/models/booking_point.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/my_bookings/data/models/my_booking_item.dart';
import 'package:injectable/injectable.dart';

/// Дисковый кэш списков бронирования (local-first UI).
@lazySingleton
class BookingLocalCache {
  BookingLocalCache(this._storage);

  final IAppStorage _storage;

  static String _periodKey(BookingListDateRange range) {
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(range.end.year, range.end.month, range.end.day);
    return '${from.toIso8601String()}_${to.toIso8601String()}';
  }

  String _myBookingsKey(String userId, BookingListDateRange range) =>
      'booking_my_bookings_${userId.trim()}_${_periodKey(range)}';

  String _hostBookingsKey(String userId, BookingListDateRange range, String? query, {String? pointId}) {
    final q = (query ?? '').trim().toLowerCase();
    final pid = (pointId ?? '').trim();
    final pointPart = pid.isEmpty ? '' : '_$pid';
    return 'booking_host_bookings_${userId.trim()}_${_periodKey(range)}_$q$pointPart';
  }

  String _myServicesKey(String userId, {String? pointId}) {
    final pid = pointId?.trim();
    if (pid == null || pid.isEmpty) return 'booking_my_services_${userId.trim()}';
    return 'booking_my_services_${userId.trim()}_$pid';
  }

  String _myStaffKey(String userId) => 'booking_my_staff_${userId.trim()}';

  String _myPointsKey(String userId) => 'booking_my_points_${userId.trim()}';

  Future<List<MyBookingItem>?> readMyBookings(String userId, BookingListDateRange range) {
    return _readList(
      _myBookingsKey(userId, range),
      MyBookingItem.fromJson,
    );
  }

  Future<void> writeMyBookings(String userId, BookingListDateRange range, List<MyBookingItem> items) {
    return _writeList(_myBookingsKey(userId, range), items, (e) => e.toJson());
  }

  Future<List<BookingListItem>?> readHostBookings(
    String userId,
    BookingListDateRange range, {
    String? query,
    String? pointId,
  }) {
    return _readList(
      _hostBookingsKey(userId, range, query, pointId: pointId),
      BookingListItem.fromJson,
    );
  }

  Future<void> writeHostBookings(
    String userId,
    BookingListDateRange range,
    List<BookingListItem> items, {
    String? query,
    String? pointId,
  }) {
    return _writeList(
      _hostBookingsKey(userId, range, query, pointId: pointId),
      items,
      (e) => e.toJson(),
    );
  }

  Future<List<BookingService>?> readMyServices(String userId, {String? pointId}) {
    return _readList(_myServicesKey(userId, pointId: pointId), BookingService.fromJson);
  }

  Future<void> writeMyServices(String userId, List<BookingService> items, {String? pointId}) {
    return _writeList(_myServicesKey(userId, pointId: pointId), items, (e) => e.toJson());
  }

  Future<List<BookingServiceExecutor>?> readMyStaff(String userId) {
    return _readList(_myStaffKey(userId), BookingServiceExecutor.fromJson);
  }

  Future<void> writeMyStaff(String userId, List<BookingServiceExecutor> items) {
    return _writeList(_myStaffKey(userId), items, (e) => e.toJson());
  }

  Future<List<BookingPoint>?> readMyPoints(String userId) {
    return _readList(_myPointsKey(userId), BookingPoint.fromJson);
  }

  Future<void> writeMyPoints(String userId, List<BookingPoint> items) {
    return _writeList(_myPointsKey(userId), items, (e) => e.toJson());
  }

  String _scheduleSettingsKey(String userId, String? pointId) {
    final pid = (pointId ?? '').trim();
    return pid.isEmpty
        ? 'booking_schedule_settings_${userId.trim()}'
        : 'booking_schedule_settings_${userId.trim()}_$pid';
  }

  String _analyticsKey(
    String userId, {
    required String pointId,
    required DateTime start,
    required DateTime end,
    String? staffId,
  }) {
    final from = DateTime(start.year, start.month, start.day).toIso8601String();
    final to = DateTime(end.year, end.month, end.day).toIso8601String();
    final sid = (staffId ?? '').trim();
    return 'booking_analytics_${userId.trim()}_${pointId.trim()}_${from}_${to}_$sid';
  }

  Future<BookingScheduleSettings?> readScheduleSettings(String userId, {String? pointId}) {
    return _storage.readObject(
      key: _scheduleSettingsKey(userId, pointId),
      fromJson: BookingScheduleSettings.fromJson,
    );
  }

  Future<void> writeScheduleSettings(
    String userId,
    BookingScheduleSettings settings, {
    String? pointId,
  }) {
    return _storage.writeObject(
      key: _scheduleSettingsKey(userId, pointId),
      value: settings,
      toJson: (s) => s.toJson(),
    );
  }

  Future<BookingAnalyticsResult?> readAnalytics(
    String userId, {
    required String pointId,
    required DateTime start,
    required DateTime end,
    String? staffId,
  }) {
    return _storage.readObject(
      key: _analyticsKey(
        userId,
        pointId: pointId,
        start: start,
        end: end,
        staffId: staffId,
      ),
      fromJson: BookingAnalyticsResult.fromJson,
    );
  }

  Future<void> writeAnalytics(
    String userId,
    BookingAnalyticsResult result, {
    required String pointId,
    required DateTime start,
    required DateTime end,
    String? staffId,
  }) {
    return _storage.writeObject(
      key: _analyticsKey(
        userId,
        pointId: pointId,
        start: start,
        end: end,
        staffId: staffId,
      ),
      value: result,
      toJson: (r) => r.toJson(),
    );
  }

  String _calendarHostsKey(String userId) => 'booking_calendar_hosts_${userId.trim()}';

  String _calendarItemsKey(String userId, String hostId, BookingListDateRange range) =>
      'booking_calendar_items_${userId.trim()}_${hostId.trim()}_${_periodKey(range)}';

  Future<List<BookingCalendarHost>?> readCalendarHosts(String userId) {
    return _readList(_calendarHostsKey(userId), BookingCalendarHost.fromJson);
  }

  Future<void> writeCalendarHosts(String userId, List<BookingCalendarHost> hosts) {
    return _writeList(_calendarHostsKey(userId), hosts, (e) => e.toJson());
  }

  Future<List<BookingCalendarItem>?> readCalendarItems(
    String userId,
    String hostId,
    BookingListDateRange range,
  ) {
    return _readList(
      _calendarItemsKey(userId, hostId, range),
      BookingCalendarItem.fromJson,
    );
  }

  Future<void> writeCalendarItems(
    String userId,
    String hostId,
    BookingListDateRange range,
    List<BookingCalendarItem> items,
  ) {
    return _writeList(
      _calendarItemsKey(userId, hostId, range),
      items,
      (e) => e.toJson(),
    );
  }

  Future<List<T>?> _readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return _storage.readList<T>(
      key: key,
      fromJson: (json) {
        if (json is! Map) throw FormatException('Expected map for $key');
        return fromJson(Map<String, dynamic>.from(json));
      },
    );
  }

  Future<void> _writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) {
    return _storage.writeList(key: key, value: items, toJson: toJson);
  }
}
