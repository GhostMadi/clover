import 'package:clover/feature/city/data/models/city_model.dart';
import 'package:clover/feature/cities/data/repository/cities_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'cities_cubit.freezed.dart';

@lazySingleton
class CitiesCubit extends Cubit<CitiesState> {
  CitiesCubit(this._repository) : super(const CitiesState.initial());

  final CitiesRepository _repository;

  /// Загрузить города для страны [countryCode] (`kz`, `ru`, …).
  Future<void> load(String countryCode) async {
    emit(const CitiesState.loading());
    try {
      final items = await _repository.fetchActiveByCountryOrdered(countryCode);
      emit(CitiesState.loaded(countryCode: countryCode.trim().toLowerCase(), items: items));
    } catch (e) {
      emit(CitiesState.error('$e'));
    }
  }
}

@freezed
class CitiesState with _$CitiesState {
  const factory CitiesState.initial() = _Initial;
  const factory CitiesState.loading() = _Loading;
  const factory CitiesState.loaded({required String countryCode, required List<CityModel> items}) = _Loaded;
  const factory CitiesState.error(String message) = _Error;
}
