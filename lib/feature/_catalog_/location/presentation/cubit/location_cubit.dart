import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

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
      emit(const LocationState.error('Не удалось загрузить местоположения'));
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
