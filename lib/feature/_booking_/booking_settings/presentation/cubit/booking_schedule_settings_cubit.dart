import 'package:clover/core/session/app_session.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:clover/feature/_booking_/booking_settings/data/models/booking_schedule_settings.dart';
import 'package:clover/feature/_booking_/booking_settings/data/repository/booking_schedule_repository.dart';
import 'package:clover/feature/_booking_/shared/data/booking_local_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingScheduleSettingsCubit extends Cubit<BookingScheduleSettingsState> {
  BookingScheduleSettingsCubit(
    this._scheduleRepository,
    this._staffRepository,
    this._cache,
    this._session,
  ) : super(const BookingScheduleSettingsState.initial());

  final BookingScheduleRepository _scheduleRepository;
  final BookingStaffRepository _staffRepository;
  final BookingLocalCache _cache;
  final AppSession _session;

  String? _pointId;

  /// Optional [pointId]: null → host default point.
  Future<void> load({String? pointId}) async {
    _pointId = pointId?.trim();
    if (_pointId != null && _pointId!.isEmpty) _pointId = null;

    final uid = _session.userId;
    if (uid != null && uid.isNotEmpty) {
      final cachedSettings = await _cache.readScheduleSettings(uid, pointId: _pointId);
      final cachedStaff = await _cache.readMyStaff(uid);
      if (!isClosed && cachedSettings != null) {
        emit(
          BookingScheduleSettingsState.loaded(
            settings: cachedSettings,
            staff: cachedStaff ?? const [],
            pointId: _pointId,
            isFromCache: true,
          ),
        );
      } else if (!isClosed) {
        emit(const BookingScheduleSettingsState.loading());
      }
    } else {
      emit(const BookingScheduleSettingsState.loading());
    }

    await _syncRemote();
  }

  Future<void> _syncRemote() async {
    try {
      final results = await Future.wait([
        _scheduleRepository.getSettings(pointId: _pointId),
        _staffRepository.listMyStaff(),
      ]);
      if (isClosed) return;
      final settings = results[0] as BookingScheduleSettings;
      final staff = results[1] as List<BookingServiceExecutor>;
      emit(
        BookingScheduleSettingsState.loaded(
          settings: settings,
          staff: staff,
          pointId: _pointId,
          isFromCache: false,
        ),
      );

      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await Future.wait([
          _cache.writeScheduleSettings(uid, settings, pointId: _pointId),
          _cache.writeMyStaff(uid, staff),
        ]);
      }
    } catch (e) {
      if (isClosed) return;
      final loaded = state.mapOrNull(loaded: (s) => s);
      if (loaded != null) return;
      emit(BookingScheduleSettingsState.error('$e'));
    }
  }

  Future<bool> save(BookingScheduleSettings settings) async {
    emit(const BookingScheduleSettingsState.submitting());
    try {
      final saved = await _scheduleRepository.saveMySettings(
        settings,
        pointId: _pointId,
      );
      if (isClosed) return false;
      final staff = switch (state) {
        BookingScheduleSettingsLoaded(:final staff) => staff,
        _ => const <BookingServiceExecutor>[],
      };
      emit(
        BookingScheduleSettingsState.loaded(
          settings: saved,
          staff: staff,
          pointId: _pointId,
        ),
      );
      final uid = _session.userId;
      if (uid != null && uid.isNotEmpty) {
        await _cache.writeScheduleSettings(uid, saved, pointId: _pointId);
      }
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(BookingScheduleSettingsState.error('$e'));
      return false;
    }
  }
}

sealed class BookingScheduleSettingsState {
  const BookingScheduleSettingsState();

  const factory BookingScheduleSettingsState.initial() = BookingScheduleSettingsInitial;
  const factory BookingScheduleSettingsState.loading() = BookingScheduleSettingsLoading;
  const factory BookingScheduleSettingsState.loaded({
    required BookingScheduleSettings settings,
    required List<BookingServiceExecutor> staff,
    String? pointId,
    bool isFromCache,
  }) = BookingScheduleSettingsLoaded;
  const factory BookingScheduleSettingsState.submitting() = BookingScheduleSettingsSubmitting;
  const factory BookingScheduleSettingsState.error(String message) = BookingScheduleSettingsError;

  T? mapOrNull<T>({
    T Function(BookingScheduleSettingsLoaded s)? loaded,
  }) {
    final self = this;
    if (self is BookingScheduleSettingsLoaded && loaded != null) return loaded(self);
    return null;
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function(BookingScheduleSettingsSubmitting s)? submitting,
    T Function(BookingScheduleSettingsLoading s)? loading,
    T Function(BookingScheduleSettingsLoaded s)? loaded,
    T Function(BookingScheduleSettingsError s)? error,
  }) {
    final self = this;
    if (self is BookingScheduleSettingsSubmitting && submitting != null) {
      return submitting(self);
    }
    if (self is BookingScheduleSettingsLoading && loading != null) return loading(self);
    if (self is BookingScheduleSettingsLoaded && loaded != null) return loaded(self);
    if (self is BookingScheduleSettingsError && error != null) return error(self);
    return orElse();
  }
}

final class BookingScheduleSettingsInitial extends BookingScheduleSettingsState {
  const BookingScheduleSettingsInitial();
}

final class BookingScheduleSettingsLoading extends BookingScheduleSettingsState {
  const BookingScheduleSettingsLoading();
}

final class BookingScheduleSettingsLoaded extends BookingScheduleSettingsState {
  const BookingScheduleSettingsLoaded({
    required this.settings,
    required this.staff,
    this.pointId,
    this.isFromCache = false,
  });

  final BookingScheduleSettings settings;
  final List<BookingServiceExecutor> staff;
  final String? pointId;
  final bool isFromCache;
}

final class BookingScheduleSettingsSubmitting extends BookingScheduleSettingsState {
  const BookingScheduleSettingsSubmitting();
}

final class BookingScheduleSettingsError extends BookingScheduleSettingsState {
  const BookingScheduleSettingsError(this.message);

  final String message;
}
