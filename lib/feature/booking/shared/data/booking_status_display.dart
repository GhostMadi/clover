import 'package:clover/feature/booking/shared/data/models/booking_status.dart';

/// Отображение статуса записи с учётом «не отмечено» (только UI, не в БД).
abstract final class BookingStatusDisplay {
  static bool isUnmarked(BookingStatus status, DateTime? endsAt) {
    if (status == BookingStatus.cancelled ||
        status == BookingStatus.completed ||
        status == BookingStatus.clientArrived ||
        status == BookingStatus.inProgress) {
      return false;
    }
    final end = endsAt?.toLocal();
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }

  static String label(BookingStatus status, {DateTime? endsAt}) {
    if (isUnmarked(status, endsAt)) return 'Не отмечено';
    return status.label;
  }

  /// Следующий статус, который host может выставить вручную.
  static BookingStatus? nextHostStatus(BookingStatus status) {
    return switch (status) {
      BookingStatus.pending => BookingStatus.confirmed,
      BookingStatus.confirmed => BookingStatus.clientArrived,
      BookingStatus.clientArrived => BookingStatus.inProgress,
      BookingStatus.inProgress => BookingStatus.completed,
      _ => null,
    };
  }

  static String actionLabel(BookingStatus nextStatus) {
    return switch (nextStatus) {
      BookingStatus.confirmed => 'Подтвердить запись',
      BookingStatus.clientArrived => 'Клиент пришёл',
      BookingStatus.inProgress => 'Начать оказание',
      BookingStatus.completed => 'Услуга оказана',
      _ => 'Отметить',
    };
  }

  static int visitStepIndex(BookingStatus status) {
    return switch (status) {
      BookingStatus.pending => 0,
      BookingStatus.confirmed => 1,
      BookingStatus.clientArrived => 2,
      BookingStatus.inProgress => 3,
      BookingStatus.completed => 4,
      _ => 0,
    };
  }

  static const visitSteps = [
    'Запись создана',
    'Подтверждена',
    'Клиент пришёл',
    'Услуга оказывается',
    'Услуга оказана',
  ];
}
