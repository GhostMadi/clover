import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';

/// Период, когда исполнитель недоступен для записи.
class BookingExecutorAbsence {
  const BookingExecutorAbsence({
    required this.id,
    required this.executorId,
    required this.startDay,
    required this.endDay,
    this.note,
  });

  final String id;
  final String executorId;
  final DateTime startDay;
  final DateTime endDay;
  final String? note;

  bool coversDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDay.year, startDay.month, startDay.day);
    final end = DateTime(endDay.year, endDay.month, endDay.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  String labelFor(BookingServiceExecutor executor) {
    final notePart = note?.trim();
    if (notePart != null && notePart.isNotEmpty) {
      return '${executor.displayName}: $notePart';
    }
    return executor.displayName;
  }

  BookingExecutorAbsence copyWith({
    String? executorId,
    DateTime? startDay,
    DateTime? endDay,
    String? note,
    bool clearNote = false,
  }) {
    return BookingExecutorAbsence(
      id: id,
      executorId: executorId ?? this.executorId,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}
