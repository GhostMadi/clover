import 'package:clover/feature/booking/booking_settings/data/models/booking_schedule_settings.dart';

/// In-memory хранилище настроек расписания (mock до подключения API).
abstract final class BookingScheduleSettingsStore {
  static BookingScheduleSettings _current = BookingScheduleSettings.defaults();

  static BookingScheduleSettings get current => _current;

  static void save(BookingScheduleSettings settings) {
    _current = settings;
  }

  static void reset() {
    _current = BookingScheduleSettings.defaults();
  }
}
