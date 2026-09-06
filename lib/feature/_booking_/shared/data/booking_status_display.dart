import 'package:clover/feature/_booking_/shared/data/models/booking_status.dart';

/// Отображение статуса записи с учётом «не отмечено» (только UI, не в БД).
abstract final class BookingStatusDisplay {
  static bool isTerminal(BookingStatus status) => status.isTerminal;

  static bool isUnmarked(BookingStatus status, DateTime? endsAt) {
    if (status.isTerminal || status == BookingStatus.clientArrived || status == BookingStatus.inProgress) {
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

  /// Следующий статус для основной кнопки host-а (пошаговый сценарий).
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
      BookingStatus.cancelled => 'Отменить визит',
      BookingStatus.noShow => 'Клиент не пришёл',
      _ => 'Отметить',
    };
  }

  static bool canHostMarkNoShow(BookingStatus status, DateTime? startsAt) {
    if (status != BookingStatus.pending && status != BookingStatus.confirmed) {
      return false;
    }
    final start = startsAt?.toLocal();
    if (start == null) return false;
    return !start.isAfter(DateTime.now());
  }

  /// Host может откатить последний шаг (не из pending / терминальных).
  static bool canHostRevert(BookingStatus status) {
    return status == BookingStatus.confirmed ||
        status == BookingStatus.clientArrived ||
        status == BookingStatus.inProgress;
  }

  /// Подпись кнопки отката (линейный fallback; RPC берёт факт из history).
  static String revertActionLabel(BookingStatus status) {
    final prev = switch (status) {
      BookingStatus.inProgress => BookingStatus.clientArrived,
      BookingStatus.clientArrived => BookingStatus.confirmed,
      BookingStatus.confirmed => BookingStatus.pending,
      _ => null,
    };
    if (prev == null) return 'Отменить последний шаг';
    return 'Вернуть: ${prev.label}';
  }

  static int visitStepIndex(BookingStatus status) {
    return switch (status) {
      BookingStatus.pending => 0,
      BookingStatus.confirmed => 1,
      BookingStatus.clientArrived => 2,
      BookingStatus.inProgress => 3,
      BookingStatus.completed => 4,
      BookingStatus.noShow => 1,
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

/// Экстренные действия host-а (меню «⋯»).
enum BookingHostEmergencyAction {
  complete,
  cancel,
  noShow,
  reschedule,
}
