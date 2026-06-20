import 'package:clover/feature/city/data/models/city_model.dart';
import 'package:clover/feature/cities/data/repository/cities_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@LazySingleton(as: CitiesRepository)
class CitiesRepositoryImpl implements CitiesRepository {
  CitiesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CityModel>> fetchActiveByCountryOrdered(String countryCode) async {
    final code = countryCode.trim().toLowerCase();
    final data = await _client
        .from('cities')
        .select()
        .eq('country_code', code)
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    final list = data as List<dynamic>;
    return list
        .map((e) => CityModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
