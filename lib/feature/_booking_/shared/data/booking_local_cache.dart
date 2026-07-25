import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/core/storage/extensions/app_storage_extensions.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_date_range.dart';
import 'package:clover/feature/_booking_/booking_list/data/models/booking_list_item.dart';
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

  String _hostBookingsKey(String userId, BookingListDateRange range, String? query) {
    final q = (query ?? '').trim().toLowerCase();
    return 'booking_host_bookings_${userId.trim()}_${_periodKey(range)}_$q';
  }

  String _myServicesKey(String userId) => 'booking_my_services_${userId.trim()}';

  String _myStaffKey(String userId) => 'booking_my_staff_${userId.trim()}';

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
  }) {
    return _readList(
      _hostBookingsKey(userId, range, query),
      BookingListItem.fromJson,
    );
  }

  Future<void> writeHostBookings(
    String userId,
    BookingListDateRange range,
    List<BookingListItem> items, {
    String? query,
  }) {
    return _writeList(
      _hostBookingsKey(userId, range, query),
      items,
      (e) => e.toJson(),
    );
  }

  Future<List<BookingService>?> readMyServices(String userId) {
    return _readList(_myServicesKey(userId), BookingService.fromJson);
  }

  Future<void> writeMyServices(String userId, List<BookingService> items) {
    return _writeList(_myServicesKey(userId), items, (e) => e.toJson());
  }

  Future<List<BookingServiceExecutor>?> readMyStaff(String userId) {
    return _readList(_myStaffKey(userId), BookingServiceExecutor.fromJson);
  }

  Future<void> writeMyStaff(String userId, List<BookingServiceExecutor> items) {
    return _writeList(_myStaffKey(userId), items, (e) => e.toJson());
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
