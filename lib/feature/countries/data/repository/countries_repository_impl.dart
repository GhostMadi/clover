import 'package:clover/feature/countries/data/models/country_model.dart';
import 'package:clover/feature/countries/data/repository/countries_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@LazySingleton(as: CountriesRepository)
class CountriesRepositoryImpl implements CountriesRepository {
  CountriesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CountryModel>> fetchActiveOrdered() async {
    final data = await _client
        .from('countries')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    final list = data as List<dynamic>;
    return list.map((e) => CountryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
