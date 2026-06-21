import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/booking/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/booking/booking_settings/data/repository/booking_schedule_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_schedule_settings_cubit.freezed.dart';

@injectable
class BookingScheduleSettingsCubit extends Cubit<BookingScheduleSettingsState> {
  BookingScheduleSettingsCubit(this._scheduleRepository, this._staffRepository)
      : super(const BookingScheduleSettingsState.initial());

  final BookingScheduleRepository _scheduleRepository;
  final BookingStaffRepository _staffRepository;

  Future<void> load() async {
    emit(const BookingScheduleSettingsState.loading());
    try {
      final results = await Future.wait([
        _scheduleRepository.getSettings(),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;
      emit(BookingScheduleSettingsState.loaded(
        settings: results[0] as BookingScheduleSettings,
        staff: results[1] as List<BookingServiceExecutor>,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(BookingScheduleSettingsState.error('$e'));
    }
  }

  Future<bool> save(BookingScheduleSettings settings) async {
    emit(const BookingScheduleSettingsState.submitting());
    try {
      final saved = await _scheduleRepository.saveMySettings(settings);
      if (isClosed) return false;
      final staff = state.mapOrNull(loaded: (s) => s.staff) ?? const [];
      emit(BookingScheduleSettingsState.loaded(settings: saved, staff: staff));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(BookingScheduleSettingsState.error('$e'));
      return false;
    }
  }
}

@freezed
class BookingScheduleSettingsState with _$BookingScheduleSettingsState {
  const factory BookingScheduleSettingsState.initial() = _Initial;
  const factory BookingScheduleSettingsState.loading() = _Loading;
  const factory BookingScheduleSettingsState.loaded({
    required BookingScheduleSettings settings,
    required List<BookingServiceExecutor> staff,
  }) = _Loaded;
  const factory BookingScheduleSettingsState.submitting() = _Submitting;
  const factory BookingScheduleSettingsState.error(String message) = _Error;
}
