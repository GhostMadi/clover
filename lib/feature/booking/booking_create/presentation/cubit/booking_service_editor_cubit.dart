import 'package:clover/feature/booking/booking_create/data/models/booking_service.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_draft.dart';
import 'package:clover/feature/booking/booking_create/data/models/booking_service_executor.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_services_repository.dart';
import 'package:clover/feature/booking/booking_create/data/repository/booking_staff_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'booking_service_editor_cubit.freezed.dart';

@injectable
class BookingServiceEditorCubit extends Cubit<BookingServiceEditorState> {
  BookingServiceEditorCubit(this._servicesRepository, this._staffRepository)
      : super(const BookingServiceEditorState.initial());

  final BookingServicesRepository _servicesRepository;
  final BookingStaffRepository _staffRepository;

  void initForCreate() {
    emit(const BookingServiceEditorState.ready(staff: []));
  }

  Future<void> loadStaff() async {
    emit(const BookingServiceEditorState.loading());
    try {
      final staff = await _staffRepository.listMyStaff();
      if (isClosed) return;
      emit(BookingServiceEditorState.ready(staff: staff));
    } catch (e) {
      if (isClosed) return;
      emit(BookingServiceEditorState.error('$e'));
    }
  }

  Future<BookingService?> create(BookingServiceDraft draft) async {
    emit(const BookingServiceEditorState.submitting());
    try {
      final staffIds = await _resolveStaffIds(draft);
      final service = await _servicesRepository.createService(draft, staffIds: staffIds);
      if (isClosed) return null;
      emit(BookingServiceEditorState.success(service));
      return service;
    } catch (e) {
      if (isClosed) return null;
      emit(BookingServiceEditorState.error('$e'));
      return null;
    }
  }

  Future<BookingService?> update(String id, BookingServiceDraft draft) async {
    emit(const BookingServiceEditorState.submitting());
    try {
      final staffIds = await _resolveStaffIds(draft);
      final service = await _servicesRepository.updateService(id, draft, staffIds: staffIds);
      if (isClosed) return null;
      emit(BookingServiceEditorState.success(service));
      return service;
    } catch (e) {
      if (isClosed) return null;
      emit(BookingServiceEditorState.error('$e'));
      return null;
    }
  }

  Future<bool> deactivate(String id) async {
    final staff = state.mapOrNull(ready: (s) => s.staff) ?? const <BookingServiceExecutor>[];
    emit(const BookingServiceEditorState.submitting());
    try {
      await _servicesRepository.deactivateService(id);
      if (isClosed) return false;
      emit(BookingServiceEditorState.ready(staff: staff));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(BookingServiceEditorState.error('$e'));
      return false;
    }
  }

  Future<List<String>> _resolveStaffIds(BookingServiceDraft draft) async {
    final ids = <String>[];
    for (final pick in draft.executors) {
      final existingStaffId = pick.staffId?.trim();
      if (existingStaffId != null && existingStaffId.isNotEmpty) {
        ids.add(existingStaffId);
        continue;
      }

      final profileId = pick.profileId?.trim();
      if (profileId == null || profileId.isEmpty) continue;

      final staff = await _staffRepository.ensureStaffFromProfile(profileId);
      ids.add(staff.id);
    }
    return ids;
  }
}

@freezed
class BookingServiceEditorState with _$BookingServiceEditorState {
  const factory BookingServiceEditorState.initial() = _Initial;
  const factory BookingServiceEditorState.loading() = _Loading;
  const factory BookingServiceEditorState.ready({
    required List<BookingServiceExecutor> staff,
  }) = _Ready;
  const factory BookingServiceEditorState.submitting() = _Submitting;
  const factory BookingServiceEditorState.success(BookingService service) = _Success;
  const factory BookingServiceEditorState.error(String message) = _Error;
}
