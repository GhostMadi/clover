import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_correction_request.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendanceCorrectionsCubit extends Cubit<AttendanceCorrectionsState> {
  AttendanceCorrectionsCubit(this._remote) : super(const AttendanceCorrectionsState.initial());

  final AttendanceRemoteRepository _remote;
  String? _workplaceId;

  Future<void> bind(String workplaceId) async {
    _workplaceId = workplaceId;
    await refresh();
  }

  Future<void> refresh() async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;
    emit(AttendanceCorrectionsState.loading(workplaceId: workplaceId));
    try {
      final items = await _remote.listPunchCorrections(workplaceId: workplaceId);
      if (isClosed) return;
      emit(AttendanceCorrectionsState.loaded(workplaceId: workplaceId, items: items));
    } catch (e) {
      if (isClosed) return;
      final msg = e is AttendanceException ? e.userMessage : 'Не удалось загрузить запросы';
      emit(AttendanceCorrectionsState.error(workplaceId: workplaceId, message: msg));
    }
  }

  Future<void> resolve({
    required String correctionId,
    required AttendanceCorrectionStatus status,
  }) async {
    final current = state;
    if (current is! AttendanceCorrectionsLoaded) return;
    if (status != AttendanceCorrectionStatus.approved && status != AttendanceCorrectionStatus.rejected) {
      return;
    }

    final prev = current.items;
    emit(
      AttendanceCorrectionsState.loaded(
        workplaceId: current.workplaceId,
        items: [
          for (final item in prev)
            if (item.id == correctionId)
              item.copyWith(status: status, resolvedAt: DateTime.now())
            else
              item,
        ],
      ),
    );

    try {
      await _remote.resolvePunchCorrection(correctionId: correctionId, status: status.key);
      await refresh();
    } catch (e) {
      if (isClosed) return;
      emit(AttendanceCorrectionsState.loaded(workplaceId: current.workplaceId, items: prev));
      rethrow;
    }
  }
}

sealed class AttendanceCorrectionsState {
  const AttendanceCorrectionsState();

  const factory AttendanceCorrectionsState.initial() = AttendanceCorrectionsInitial;
  const factory AttendanceCorrectionsState.loading({required String workplaceId}) =
      AttendanceCorrectionsLoading;
  const factory AttendanceCorrectionsState.loaded({
    required String workplaceId,
    required List<AttendanceCorrectionRequest> items,
  }) = AttendanceCorrectionsLoaded;
  const factory AttendanceCorrectionsState.error({
    required String workplaceId,
    required String message,
  }) = AttendanceCorrectionsError;
}

final class AttendanceCorrectionsInitial extends AttendanceCorrectionsState {
  const AttendanceCorrectionsInitial();
}

final class AttendanceCorrectionsLoading extends AttendanceCorrectionsState {
  const AttendanceCorrectionsLoading({required this.workplaceId});
  final String workplaceId;
}

final class AttendanceCorrectionsLoaded extends AttendanceCorrectionsState {
  const AttendanceCorrectionsLoaded({required this.workplaceId, required this.items});
  final String workplaceId;
  final List<AttendanceCorrectionRequest> items;
}

final class AttendanceCorrectionsError extends AttendanceCorrectionsState {
  const AttendanceCorrectionsError({required this.workplaceId, required this.message});
  final String workplaceId;
  final String message;
}
