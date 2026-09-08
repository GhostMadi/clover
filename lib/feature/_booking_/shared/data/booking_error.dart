import 'package:supabase_flutter/supabase_flutter.dart';

enum BookingErrorCode {
  notAuthenticated,
  slotConflict,
  notAvailable,
  invalidService,
  invalidStaff,
  alreadyStaff,
  outsideSchedule,
  hostDisabled,
  serviceHasFutureBookings,
  cancelTooLate,
  nothingToRevert,
  forbidden,
  unknown,
}

class BookingException implements Exception {
  const BookingException(this.code, [this.message]);

  final BookingErrorCode code;
  final String? message;

  @override
  String toString() => message ?? code.name;

  static BookingException from(Object error) {
    if (error is BookingException) return error;

    if (error is PostgrestException) {
      return BookingException(_codeFromPostgres(error), error.message);
    }

    return BookingException(BookingErrorCode.unknown, '$error');
  }

  static BookingErrorCode _codeFromPostgres(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('cancel_too_late')) {
      return BookingErrorCode.cancelTooLate;
    }
    if (message.contains('no_show_too_early')) {
      return BookingErrorCode.notAvailable;
    }
    if (message.contains('nothing_to_revert')) {
      return BookingErrorCode.nothingToRevert;
    }
    if (message.contains('already_staff')) {
      return BookingErrorCode.alreadyStaff;
    }
    if (message.contains('self_booking')) {
      return BookingErrorCode.forbidden;
    }
    if (message.contains('invalid_status')) {
      return BookingErrorCode.notAvailable;
    }
    return switch (error.code) {
      'P0003' => BookingErrorCode.notAuthenticated,
      'P0020' => BookingErrorCode.notAvailable,
      'P0021' => BookingErrorCode.slotConflict,
      'P0022' => BookingErrorCode.invalidService,
      'P0023' => message.contains('already') ? BookingErrorCode.alreadyStaff : BookingErrorCode.invalidStaff,
      'P0024' => BookingErrorCode.outsideSchedule,
      'P0025' => BookingErrorCode.hostDisabled,
      'P0026' => BookingErrorCode.serviceHasFutureBookings,
      'P0009' => BookingErrorCode.forbidden,
      _ => BookingErrorCode.unknown,
    };
  }

  String get userMessage => switch (code) {
        BookingErrorCode.notAuthenticated => 'Войдите в аккаунт',
        BookingErrorCode.slotConflict => 'Это время уже занято',
        BookingErrorCode.notAvailable => 'Запись недоступна в этот день',
        BookingErrorCode.nothingToRevert => 'Нечего откатывать — нет предыдущего шага',
        BookingErrorCode.invalidService => 'Услуга недоступна',
        BookingErrorCode.invalidStaff => 'Мастер недоступен',
        BookingErrorCode.alreadyStaff => 'Этот аккаунт уже в исполнителях',
        BookingErrorCode.outsideSchedule => 'Время вне расписания',
        BookingErrorCode.hostDisabled => 'Запись у этого аккаунта недоступна',
        BookingErrorCode.serviceHasFutureBookings =>
          'Нельзя отключить услугу — есть будущие записи',
        BookingErrorCode.cancelTooLate => 'Отменить запись уже нельзя — окно отмены закрыто',
        BookingErrorCode.forbidden => 'Недостаточно прав',
        BookingErrorCode.unknown => message ?? 'Не удалось выполнить операцию',
      };
}
