import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/locale/app_locale_cubit.dart';
import 'package:clover/l10n/app_localizations.dart';

part 'location_cubit.freezed.dart';

@injectable
class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this._repository) : super(const LocationState.initial());

  final LocationRepository _repository;

  Future<void> load() async {
    if (isClosed) return;
    emit(const LocationState.loading());
    try {
      final items = await _repository.listMine();
      if (isClosed) return;
      emit(LocationState.loaded(items));
    } catch (_) {
      if (isClosed) return;
      emit(LocationState.error(lookupAppLocalizations(sl<AppLocaleCubit>().state.locale).catalog_locations_load_failed));
    }
  }
}

@freezed
class LocationState with _$LocationState {
  const factory LocationState.initial() = _Initial;
  const factory LocationState.loading() = _Loading;
  const factory LocationState.loaded(List<LocationModel> items) = _Loaded;
  const factory LocationState.error(String message) = _Error;
}
