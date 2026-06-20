import 'package:clover/core/shared/app_date_picker.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_executor_absence.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_weekday.dart';

enum BookingHorizonKind { daysAhead, untilDate }

/// Общие настройки расписания записи для аккаунта.
class BookingScheduleSettings {
  const BookingScheduleSettings({
    required this.restWeekdays,
    required this.horizonKind,
    required this.maxBookingDaysAhead,
    required this.maxBookingUntilDate,
    required this.workStartHour,
    required this.workStartMinute,
    required this.workEndHour,
    required this.workEndMinute,
    required this.executorAbsences,
  });

  /// Выходные дни недели (1 = пн … 7 = вс).
  final Set<int> restWeekdays;
  final BookingHorizonKind horizonKind;
  final int maxBookingDaysAhead;
  final DateTime? maxBookingUntilDate;
  final int workStartHour;
  final int workStartMinute;
  final int workEndHour;
  final int workEndMinute;
  final List<BookingExecutorAbsence> executorAbsences;

  factory BookingScheduleSettings.defaults() {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final nextWeekStart = base.add(const Duration(days: 7));
    return BookingScheduleSettings(
      restWeekdays: {BookingWeekday.sunday.isoWeekday},
      horizonKind: BookingHorizonKind.daysAhead,
      maxBookingDaysAhead: 14,
      maxBookingUntilDate: base.add(const Duration(days: 14)),
      workStartHour: 9,
      workStartMinute: 0,
      workEndHour: 20,
      workEndMinute: 0,
      executorAbsences: [
        BookingExecutorAbsence(
          id: 'abs-1',
          executorId: 'exec-2',
          startDay: nextWeekStart,
          endDay: nextWeekStart.add(const Duration(days: 2)),
          note: 'Отпуск',
        ),
      ],
    );
  }

  DateTime get lastBookableDay {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return switch (horizonKind) {
      BookingHorizonKind.daysAhead => base.add(Duration(days: maxBookingDaysAhead)),
      BookingHorizonKind.untilDate => maxBookingUntilDate ?? base.add(const Duration(days: 14)),
    };
  }

  bool isRestDay(DateTime day) => restWeekdays.contains(day.weekday);

  bool isExecutorAbsent(String executorId, DateTime day) {
    for (final absence in executorAbsences) {
      if (absence.executorId == executorId && absence.coversDay(day)) return true;
    }
    return false;
  }

  String? absenceNoteFor(String executorId, DateTime day) {
    for (final absence in executorAbsences) {
      if (absence.executorId == executorId && absence.coversDay(day)) {
        return absence.note;
      }
    }
    return null;
  }

  String get workingHoursLabel {
    return '${_time(workStartHour, workStartMinute)} — ${_time(workEndHour, workEndMinute)}';
  }

  String get restDaysLabel => BookingWeekday.joinedShortLabels(restWeekdays);

  String get maxHorizonLabel {
    if (horizonKind == BookingHorizonKind.untilDate && maxBookingUntilDate != null) {
      return 'до ${AppDatePicker.formatDisplay(maxBookingUntilDate!)}';
    }
    if (maxBookingDaysAhead % 7 == 0) {
      final weeks = maxBookingDaysAhead ~/ 7;
      return weeks == 1 ? '1 неделя' : '$weeks нед.';
    }
    return '$maxBookingDaysAhead дн.';
  }

  bool get isValid {
    final startMinutes = workStartHour * 60 + workStartMinute;
    final endMinutes = workEndHour * 60 + workEndMinute;
    if (endMinutes <= startMinutes) return false;

    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);

    return switch (horizonKind) {
      BookingHorizonKind.daysAhead => maxBookingDaysAhead >= 1,
      BookingHorizonKind.untilDate => () {
        final until = maxBookingUntilDate;
        if (until == null) return false;
        final last = DateTime(until.year, until.month, until.day);
        return !last.isBefore(base);
      }(),
    };
  }

  BookingScheduleSettings copyWith({
    Set<int>? restWeekdays,
    BookingHorizonKind? horizonKind,
    int? maxBookingDaysAhead,
    DateTime? maxBookingUntilDate,
    bool clearMaxBookingUntilDate = false,
    int? workStartHour,
    int? workStartMinute,
    int? workEndHour,
    int? workEndMinute,
    List<BookingExecutorAbsence>? executorAbsences,
  }) {
    return BookingScheduleSettings(
      restWeekdays: restWeekdays ?? this.restWeekdays,
      horizonKind: horizonKind ?? this.horizonKind,
      maxBookingDaysAhead: maxBookingDaysAhead ?? this.maxBookingDaysAhead,
      maxBookingUntilDate: clearMaxBookingUntilDate
          ? null
          : (maxBookingUntilDate ?? this.maxBookingUntilDate),
      workStartHour: workStartHour ?? this.workStartHour,
      workStartMinute: workStartMinute ?? this.workStartMinute,
      workEndHour: workEndHour ?? this.workEndHour,
      workEndMinute: workEndMinute ?? this.workEndMinute,
      executorAbsences: executorAbsences ?? this.executorAbsences,
    );
  }

  static String _time(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
