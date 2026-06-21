import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/shared/data/models/booking_status.dart';
import 'package:clover/feature/booking/my_bookings/data/models/my_booking_item.dart';

/// In-memory записи, созданные клиентом в текущей сессии (mock).
abstract final class ClientBookingSubmissionsStore {
  static final List<MyBookingItem> _items = [];

  static List<MyBookingItem> get items => List.unmodifiable(_items);

  static MyBookingItem submit({
    required String hostId,
    required String hostDisplayName,
    required BookingService service,
    required BookingServiceExecutor executor,
    required DateTime startsAt,
    String? clientComment,
  }) {
    final now = DateTime.now();
    final notes = clientComment?.trim();
    final item = MyBookingItem(
      id: 'mb-client-${now.microsecondsSinceEpoch}',
      hostId: hostId,
      hostDisplayName: hostDisplayName,
      serviceTitle: service.title,
      serviceEmoji: service.emojiText,
      durationMinutes: service.durationMinutes,
      price: service.price,
      executorName: executor.displayName,
      startsAt: _formatDateTime(startsAt),
      createdAt: _formatDateTime(now),
      status: BookingStatus.pending,
      notes: notes != null && notes.isNotEmpty ? notes : null,
    );
    _items.insert(0, item);
    return item;
  }

  static void reset() {
    _items.clear();
  }

  static String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00';
  }
}
