import 'package:clover/feature/city/data/models/city_model.dart';
import 'package:clover/feature/countries/data/models/country_model.dart';
import 'package:clover/feature/currencies/data/models/currency_model.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/profile_categories/data/models/profile_category_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Сетевые запросы справочников (без кэша).
@lazySingleton
class DictionaryNetworkSource {
  DictionaryNetworkSource(this._client);

  final SupabaseClient _client;

  static const _tagColumns = '''
id,
key,
group_key,
created_at
''';

  Future<List<CountryModel>> fetchCountries() async {
    final data = await _client
        .from('countries')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return _mapList(data, CountryModel.fromJson);
  }

  Future<List<CityModel>> fetchCities() async {
    final data = await _client
        .from('cities')
        .select()
        .eq('is_active', true)
        .order('country_code')
        .order('sort_order', ascending: true);

    return _mapList(data, CityModel.fromJson);
  }

  Future<List<MarkerTagModel>> fetchMarkerTags() async {
    final data = await _client.from('marker_tags').select(_tagColumns).order('group_key').order('key');

    return _mapList(data, MarkerTagModel.fromJson);
  }

  Future<List<CurrencyModel>> fetchCurrencies() async {
    final data = await _client
        .from('currencies')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return _mapList(data, CurrencyModel.fromJson);
  }

  Future<List<ProfileCategoryModel>> fetchCategories() async {
    final data = await _client
        .from('profile_categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return _mapList(data, ProfileCategoryModel.fromJson);
  }

  List<T> _mapList<T>(Object? data, T Function(Map<String, dynamic> json) fromJson) {
    final list = data as List<dynamic>;
    return list.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false);
  }
}
