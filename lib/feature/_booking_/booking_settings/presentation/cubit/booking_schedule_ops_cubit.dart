import 'package:clover/feature/_booking_/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/_booking_/booking_settings/data/repository/booking_ops_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class BookingScheduleOpsCubit extends Cubit<BookingScheduleOpsState> {
  BookingScheduleOpsCubit(this._ops) : super(const BookingScheduleOpsState.initial());

  final BookingOpsRepository _ops;
  List<BookingServiceExecutor> _executors = const [];

  Future<void> bind(List<BookingServiceExecutor> executors, {required String pointId}) async {
    _pointId = pointId.trim();
    _executors = executors;
    await Future.wait([_loadBlocked(), _loadScheduleForFirst()]);
  }

  String _pointId = '';

  Future<void> _loadBlocked() async {
    emit(state.copyWith(loadingBlocked: true));
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final list = await _ops.listBlockedSlots(
        from: from,
        to: from.add(const Duration(days: 60)),
        pointId: _pointId,
      );
      emit(state.copyWith(blocked: list, loadingBlocked: false));
    } catch (_) {
      emit(state.copyWith(loadingBlocked: false));
    }
  }

  Future<void> _loadScheduleForFirst() async {
    if (_executors.isEmpty) return;
    final id = state.scheduleStaffId ?? _executors.first.id;
    await selectStaff(id);
  }

  Future<void> selectStaff(String staffId) async {
    emit(state.copyWith(scheduleStaffId: staffId, loadingSchedule: true));
    try {
      final days = await _ops.listStaffSchedule(staffId);
      emit(state.copyWith(days: days, loadingSchedule: false));
    } catch (_) {
      emit(state.copyWith(loadingSchedule: false));
    }
  }

  Future<void> addBlocked({
    required String staffId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  }) async {
    await _ops.createBlockedSlot(
      pointId: _pointId,
      staffId: staffId,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
    );
    await _loadBlocked();
  }

  Future<void> deleteBlocked(String id) async {
    await _ops.deleteBlockedSlot(id);
    await _loadBlocked();
  }

  Future<void> toggleWeekday({
    required int weekday,
    required bool isWorking,
    int? workStartHour,
    int? workEndHour,
  }) async {
    final staffId = state.scheduleStaffId;
    if (staffId == null) return;
    await _ops.upsertStaffDay(
      staffId: staffId,
      weekday: weekday,
      isWorking: isWorking,
      workStartHour: workStartHour,
      workEndHour: workEndHour,
    );
    await selectStaff(staffId);
  }
}

class BookingScheduleOpsState {
  const BookingScheduleOpsState({
    this.blocked = const [],
    this.days = const [],
    this.scheduleStaffId,
    this.loadingBlocked = false,
    this.loadingSchedule = false,
  });

  const BookingScheduleOpsState.initial() : this();

  final List<BookingBlockedSlot> blocked;
  final List<BookingStaffDaySchedule> days;
  final String? scheduleStaffId;
  final bool loadingBlocked;
  final bool loadingSchedule;

  BookingScheduleOpsState copyWith({
    List<BookingBlockedSlot>? blocked,
    List<BookingStaffDaySchedule>? days,
    String? scheduleStaffId,
    bool? loadingBlocked,
    bool? loadingSchedule,
  }) {
    return BookingScheduleOpsState(
      blocked: blocked ?? this.blocked,
      days: days ?? this.days,
      scheduleStaffId: scheduleStaffId ?? this.scheduleStaffId,
      loadingBlocked: loadingBlocked ?? this.loadingBlocked,
      loadingSchedule: loadingSchedule ?? this.loadingSchedule,
    );
  }
}
