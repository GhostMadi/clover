import 'package:clover/feature/_catalog_/countries/data/models/country_model.dart';
import 'package:clover/feature/_catalog_/countries/data/repository/countries_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
part 'countries_cubit.freezed.dart';

@lazySingleton
class CountriesCubit extends Cubit<CountriesState> {
  CountriesCubit(this._repository) : super(const CountriesState.initial());

  final CountriesRepository _repository;

  Future<void> load() async {
    emit(const CountriesState.loading());
    try {
      final items = await _repository.fetchActiveOrdered();
      emit(CountriesState.loaded(items));
    } catch (e) {
      emit(CountriesState.error('$e'));
    }
  }
}

@freezed
class CountriesState with _$CountriesState {
  const factory CountriesState.initial() = _Initial;
  const factory CountriesState.loading() = _Loading;
  const factory CountriesState.loaded(List<CountryModel> items) = _Loaded;
  const factory CountriesState.error(String message) = _Error;
}
