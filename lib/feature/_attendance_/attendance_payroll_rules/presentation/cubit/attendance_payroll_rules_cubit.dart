import 'dart:async';

import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_error.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_outbox.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_payroll_calc.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_remote_repository.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_payroll_models.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_workplace.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AttendancePayrollRulesCubit extends Cubit<AttendancePayrollRulesState> {
  AttendancePayrollRulesCubit(this._store, this._remote, this._outbox)
    : super(AttendancePayrollRulesState.initial()) {
    _store.snapshot.addListener(_onSnapshot);
  }

  final AttendanceContextStore _store;
  final AttendanceRemoteRepository _remote;
  final AttendanceOutbox _outbox;

  String? _workplaceId;
  Timer? _previewDebounce;
  int _previewRequest = 0;

  @override
  Future<void> close() {
    _previewDebounce?.cancel();
    _store.snapshot.removeListener(_onSnapshot);
    return super.close();
  }

  void bind(String workplaceId) {
    _workplaceId = workplaceId;
    final workplace = _store.snapshot.value?.workplaceById(workplaceId);
    if (workplace == null) return;
    emit(state.copyWith(workplace: workplace, rules: workplace.payrollRules));
    unawaited(reloadPreview());
  }

  void setRules(AttendancePayrollRules rules) {
    emit(state.copyWith(rules: rules));
    if (!_store.isRemote) {
      _loadLocalPreview();
      return;
    }
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(reloadPreview()),
    );
  }

  Future<void> reloadPreview() async {
    final workplaceId = _workplaceId;
    final workplace = state.workplace;
    if (workplaceId == null || workplace == null) return;
    if (!_store.isRemote) {
      _loadLocalPreview();
      return;
    }

    final request = ++_previewRequest;
    emit(state.copyWith(loadingPreview: true));
    final now = DateTime.now();
    try {
      final summary = await _remote.payrollPreview(
        workplaceId: workplaceId,
        start: DateTime(now.year, now.month),
        end: now,
        rulesJson: state.rules.toJson(),
      );
      if (isClosed || request != _previewRequest) return;
      emit(
        state.copyWith(
          summary: summary,
          rows: summary.rows,
          loadingPreview: false,
        ),
      );
    } catch (_) {
      if (isClosed || request != _previewRequest) return;
      emit(state.copyWith(loadingPreview: false));
    }
  }

  Future<AttendancePersistResult> save() async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;
    final rules = state.rules;
    emit(state.copyWith(saving: true));

    void optimistic() => _patchRules(workplaceId, rules);

    try {
      if (!_store.isRemote) {
        optimistic();
        return AttendancePersistResult.synced;
      }
      await _remote.updatePayrollSettings(
        workplaceId: workplaceId,
        payrollRules: rules.toJson(),
      );
      await _store.refreshRemote();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'payroll_$workplaceId',
          kind: AttendanceOutboxKind.payrollSettings,
          payload: {
            'workplace_id': workplaceId,
            'payroll_rules': rules.toJson(),
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    } finally {
      if (!isClosed) emit(state.copyWith(saving: false));
    }
  }

  Future<AttendancePersistResult> updateWorkerBaseSalary({
    required String workerId,
    required int baseSalary,
  }) async {
    final workplaceId = _workplaceId;
    if (workplaceId == null) return AttendancePersistResult.synced;

    void optimistic() => _patchSalary(
      workplaceId: workplaceId,
      workerId: workerId,
      baseSalary: baseSalary,
    );

    if (!_store.isRemote) {
      optimistic();
      return AttendancePersistResult.synced;
    }

    try {
      await _remote.setMemberBaseSalary(
        workplaceId: workplaceId,
        profileId: workerId,
        baseSalaryTenge: baseSalary,
      );
      await _store.refreshRemote();
      await reloadPreview();
      return AttendancePersistResult.synced;
    } on AttendanceException catch (e) {
      if (!e.isRetriableNetwork) rethrow;
      optimistic();
      await _outbox.enqueue(
        AttendanceOutboxItem(
          id: 'salary_${workplaceId}_$workerId',
          kind: AttendanceOutboxKind.memberBaseSalary,
          payload: {
            'workplace_id': workplaceId,
            'profile_id': workerId,
            'base_salary_tenge': baseSalary,
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return AttendancePersistResult.queued;
    }
  }

  void _onSnapshot() {
    if (isClosed) return;
    final workplaceId = _workplaceId;
    if (workplaceId == null) return;
    final workplace = _store.snapshot.value?.workplaceById(workplaceId);
    if (workplace == null) return;
    final isFirstLoad = state.workplace == null;
    emit(
      state.copyWith(
        workplace: workplace,
        rules: isFirstLoad ? workplace.payrollRules : state.rules,
      ),
    );
    if (_store.isRemote) {
      if (isFirstLoad) unawaited(reloadPreview());
    } else {
      _loadLocalPreview();
    }
  }

  void _loadLocalPreview() {
    final workplace = state.workplace;
    final snapshot = _store.snapshot.value;
    if (workplace == null || snapshot == null) return;
    final previewWorkplace = workplace.copyWith(payrollRules: state.rules);
    final rows = AttendancePayrollCalc.forWorkplace(
      previewWorkplace,
      snapshot: snapshot,
    );
    emit(
      state.copyWith(
        summary: AttendancePayrollTeamSummary.fromRows(
          periodLabel: AttendancePayrollCalc.periodLabel(),
          rows: rows,
        ),
        rows: rows,
        loadingPreview: false,
      ),
    );
  }

  void _patchRules(String workplaceId, AttendancePayrollRules rules) {
    _store.patch((snapshot) {
      final workplaces = snapshot.workplaces
          .map(
            (workplace) => workplace.id == workplaceId
                ? workplace.copyWith(payrollRules: rules)
                : workplace,
          )
          .toList(growable: false);
      return snapshot.copyWith(workplaces: workplaces);
    });
  }

  void _patchSalary({
    required String workplaceId,
    required String workerId,
    required int baseSalary,
  }) {
    _store.patch((snapshot) {
      final workplaces = snapshot.workplaces
          .map((workplace) {
            if (workplace.id != workplaceId) return workplace;
            final salaries = Map<String, int>.from(
              workplace.workerBaseSalaries,
            );
            salaries[workerId] = baseSalary;
            return workplace.copyWith(workerBaseSalaries: salaries);
          })
          .toList(growable: false);
      return snapshot.copyWith(workplaces: workplaces);
    });
  }
}

class AttendancePayrollRulesState {
  const AttendancePayrollRulesState({
    required this.workplace,
    required this.rules,
    required this.summary,
    required this.rows,
    required this.loadingPreview,
    required this.saving,
  });

  factory AttendancePayrollRulesState.initial() => AttendancePayrollRulesState(
    workplace: null,
    rules: const AttendancePayrollRules(),
    summary: AttendancePayrollTeamSummary.fromRows(
      periodLabel: AttendancePayrollCalc.periodLabel(),
      rows: const [],
    ),
    rows: const [],
    loadingPreview: false,
    saving: false,
  );

  final AttendanceWorkplace? workplace;
  final AttendancePayrollRules rules;
  final AttendancePayrollTeamSummary summary;
  final List<AttendanceWorkerPayroll> rows;
  final bool loadingPreview;
  final bool saving;

  AttendancePayrollRulesState copyWith({
    AttendanceWorkplace? workplace,
    AttendancePayrollRules? rules,
    AttendancePayrollTeamSummary? summary,
    List<AttendanceWorkerPayroll>? rows,
    bool? loadingPreview,
    bool? saving,
  }) {
    return AttendancePayrollRulesState(
      workplace: workplace ?? this.workplace,
      rules: rules ?? this.rules,
      summary: summary ?? this.summary,
      rows: rows ?? this.rows,
      loadingPreview: loadingPreview ?? this.loadingPreview,
      saving: saving ?? this.saving,
    );
  }
}
