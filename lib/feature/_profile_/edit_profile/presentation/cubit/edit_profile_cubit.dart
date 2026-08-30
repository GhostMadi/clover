import 'package:clover/feature/_profile_/edit_profile/data/models/edit_profile_error.dart';
import 'package:clover/feature/_profile_/edit_profile/data/models/edit_profile_save_input.dart';
import 'package:clover/feature/_profile_/edit_profile/data/repository/edit_profile_repository.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'edit_profile_cubit.freezed.dart';

@injectable
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit(this._repository) : super(const EditProfileState.idle());

  final EditProfileRepository _repository;

  Future<ProfileNewModel?> saveProfile(EditProfileSaveInput input) async {
    if (state.mapOrNull(saving: (_) => true, savingUsername: (_) => true) ?? false) {
      return null;
    }

    emit(const EditProfileState.saving());

    try {
      final profile = await _repository.updateProfile(input);
      if (isClosed) return null;
      emit(EditProfileState.saved(profile));
      return profile;
    } catch (error) {
      if (isClosed) return null;
      emit(EditProfileState.error(EditProfileError.from(error).message));
      return null;
    }
  }

  Future<ProfileNewModel?> saveUsername(String username) async {
    if (state.mapOrNull(saving: (_) => true, savingUsername: (_) => true) ?? false) {
      return null;
    }

    emit(const EditProfileState.savingUsername());

    try {
      final profile = await _repository.updateUsername(username);
      if (isClosed) return null;
      emit(EditProfileState.saved(profile));
      return profile;
    } catch (error) {
      if (isClosed) return null;
      emit(EditProfileState.error(EditProfileError.from(error).message));
      return null;
    }
  }

  void clearFeedback() {
    emit(const EditProfileState.idle());
  }
}

@freezed
class EditProfileState with _$EditProfileState {
  const factory EditProfileState.idle() = EditProfileIdle;
  const factory EditProfileState.saving() = EditProfileSaving;
  const factory EditProfileState.savingUsername() = EditProfileSavingUsername;
  const factory EditProfileState.saved(ProfileNewModel profile) = EditProfileSaved;
  const factory EditProfileState.error(String message) = EditProfileErrorState;
}
