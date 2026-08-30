import 'package:clover/feature/_bonus_/bonus_settings/data/models/bonus_program_settings.dart';
import 'package:clover/feature/_bonus_/bonus_settings/data/repository/bonus_program_repository.dart';
import 'package:clover/feature/_bonus_/shared/data/models/bonus_program_status.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'bonus_program_settings_cubit.freezed.dart';

@injectable
class BonusProgramSettingsCubit extends Cubit<BonusProgramSettingsState> {
  BonusProgramSettingsCubit(this._repository, this._profileCubit)
      : super(const BonusProgramSettingsState.initial());

  final BonusProgramRepository _repository;
  final ProfileCubit _profileCubit;

  void init() {
    final initialStatus = _profileCubit.state.maybeMap(
      loaded: (s) => s.profile.bonusProgramStatus,
      orElse: () => BonusProgramStatus.inactive,
    );
    emit(
      BonusProgramSettingsState.ready(
        initial: BonusProgramSettings.fromStatus(initialStatus),
        draft: BonusProgramSettings.fromStatus(initialStatus),
      ),
    );
  }

  void updateDraft(BonusProgramSettings settings) {
    final cur = state;
    if (cur is! BonusProgramSettingsReady) return;
    emit(cur.copyWith(draft: settings));
  }

  Future<bool> save() async {
    final cur = state;
    if (cur is! BonusProgramSettingsReady || cur.isSaving) return false;
    if (cur.draft.status == cur.initial.status) return true;

    emit(cur.copyWith(isSaving: true, errorMessage: null));
    try {
      final saved = await _repository.updateMyProgramStatus(cur.draft.status);
      if (isClosed) return false;

      _profileCubit.patchBonusProgramStatus(saved);
      emit(
        BonusProgramSettingsState.ready(
          initial: BonusProgramSettings.fromStatus(saved),
          draft: BonusProgramSettings.fromStatus(saved),
        ),
      );
      return true;
    } on BonusProgramException catch (error) {
      if (isClosed) return false;
      emit(cur.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    } catch (error) {
      if (isClosed) return false;
      emit(cur.copyWith(isSaving: false, errorMessage: '$error'));
      return false;
    }
  }
}

@freezed
class BonusProgramSettingsState with _$BonusProgramSettingsState {
  const factory BonusProgramSettingsState.initial() = BonusProgramSettingsInitial;

  const factory BonusProgramSettingsState.ready({
    required BonusProgramSettings initial,
    required BonusProgramSettings draft,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = BonusProgramSettingsReady;

  const factory BonusProgramSettingsState.error(String message) = BonusProgramSettingsError;
}
